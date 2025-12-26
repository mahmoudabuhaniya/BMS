# myapp/utils/households.py
import uuid
from collections import deque, defaultdict
from django.db import transaction
from django.db.models import Q
from .models import Beneficiary

@transaction.atomic
def assign_households():
    """
    Build connected components using Parent_ID and Spouse_ID and assign a single
    Household_ID (string UUID) for each connected component.

    Rules:
    - If any member of a connected component already has a Household_ID, reuse it.
    - Otherwise, generate a new UUID string and assign to all members.
    - Works with either ID_Number or record_id references (we try to match both).
    """

    # Load minimal necessary fields into memory (reduce DB hits)
    qs = Beneficiary.all_objects.all().values(
        "id", "record_id", "ID_Number", "Parent_ID", "Spouse_ID", "Household_ID"
    )
    # Build lookup maps:
    by_record = {}     # record_id -> db id
    by_idnum = {}      # ID_Number -> db id
    rows = {}          # db id -> row dict

    for r in qs:
        rows[r["id"]] = r
        if r["record_id"]:
            by_record[str(r["record_id"])] = r["id"]
        if r["ID_Number"]:
            by_idnum[str(r["ID_Number"])] = r["id"]

    # Helper: find possible neighbor ids for a row (both directions will be handled)
    def neighbors_for_row(row):
        nbrs = set()
        # Parent_ID might reference an ID_Number or a record_id
        for ref in (row.get("Parent_ID"), row.get("Spouse_ID"), row.get("ID_Number")):
            if not ref:
                continue
            ref = str(ref)
            if ref in by_record:
                nbrs.add(by_record[ref])
            if ref in by_idnum:
                nbrs.add(by_idnum[ref])
            # Also if ref equals a Household_ID string (rare), we skip - not used here.
        return nbrs

    visited = set()
    updates = []  # collect tuples (db_id, household_id) to bulk update later

    # For reverse lookup (who references whom) we use DB queries in batches to avoid O(n^2)
    # Build reference map: reference_value -> set of db ids who reference it
    reference_map = defaultdict(set)
    for r in qs:
        if r["ID_Number"]:
            reference_map[str(r["ID_Number"])].add(r["id"])
        if r["Parent_ID"]:
            reference_map[str(r["Parent_ID"])].add(r["id"])
        if r["Spouse_ID"]:
            reference_map[str(r["Spouse_ID"])].add(r["id"])

    # Graph traversal across all nodes
    for start_id, row in rows.items():
        if start_id in visited:
            continue

        # BFS to collect connected component
        queue = deque([start_id])
        component = set()
        existing_household = None

        while queue:
            cur = queue.popleft()
            if cur in visited:
                continue
            visited.add(cur)
            component.add(cur)
            cur_row = rows[cur]

            # If any member already has Household_ID, capture it (reuse it)
            if cur_row.get("Household_ID"):
                existing_household = existing_household or cur_row["Household_ID"]

            # Neighbors via this row's Parent_ID/Spouse_ID references
            for nbr in neighbors_for_row(cur_row):
                if nbr not in visited:
                    queue.append(nbr)

            # Neighbors via other rows referencing this row's record_id or ID_Number
            # check record_id
            if cur_row.get("record_id"):
                ref = str(cur_row["record_id"])
                for referrer in reference_map.get(ref, ()):
                    if referrer not in visited:
                        queue.append(referrer)
            # check ID_Number
            if cur_row.get("ID_Number"):
                ref = str(cur_row["ID_Number"])
                for referrer in reference_map.get(ref, ()):
                    if referrer not in visited:
                        queue.append(referrer)

        # Determine household id: reuse or create
        if existing_household:
            household_id = existing_household
        else:
            household_id = str(uuid.uuid4())

        # Record updates
        for member_id in component:
            # Only push update if new or different
            old_h = rows[member_id].get("Household_ID")
            if old_h != household_id:
                updates.append((member_id, household_id))

    # Bulk update DB (do it in batches)
    if updates:
        # Build id -> household map
        id_to_household = {mid: hid for mid, hid in updates}
        objs = []
        # Fetch actual objects in one query
        beneficiaries = Beneficiary.objects.filter(id__in=id_to_household.keys())
        for b in beneficiaries:
            b.Household_ID = id_to_household[b.id]
            objs.append(b)
        # Bulk update the field
        Beneficiary.objects.bulk_update(objs, ["Household_ID"])
    updated_count = len(updates)
    return updated_count  # return number of updated rows (optional)
