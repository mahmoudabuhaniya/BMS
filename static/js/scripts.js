function startSync(event) {
    event.preventDefault();

    const form = document.getElementById('sync-form');
    const progressUrl = form.dataset.progressUrl;
    const csrfToken = document.getElementById('csrf-token').dataset.csrfToken;

    document.getElementById('progress-container').style.display = 'block';
    const progressBar = document.getElementById('progress-bar');
    const progressMessage = document.getElementById('progress-message');

    let syncCompleted = false;

    // Start sync
    fetch(form.action, {
        method: 'POST',
        headers: {
            'X-CSRFToken': csrfToken,
        },
    })
        .then(response => {
            if (!response.ok) {
                throw new Error('Sync failed.');
            }
            return response.json();
        })
        .then(data => {
            progressMessage.textContent = data.message || "Sync complete!";
            progressBar.style.width = '100%';
            progressBar.classList.remove('progress-bar-striped', 'progress-bar-animated');
            syncCompleted = true;

            setTimeout(() => location.reload(), 3000);
        })
        .catch(error => {
            progressMessage.textContent = "Error: " + error.message;
        });

    // Poll progress
    const interval = setInterval(() => {
        fetch(progressUrl)
            .then(response => response.json())
            .then(data => {
                progressMessage.textContent = data.stage;
                progressBar.style.width = data.progress + '%';

                if (data.progress === 100 || syncCompleted) {
                    clearInterval(interval);
                    progressMessage.textContent = "Sync completed!";
                }
            })
            .catch(error => {
                clearInterval(interval);
                progressMessage.textContent = "Error: Unable to fetch progress.";
            });
    }, 1000);
}


// Smooth scrolling for pagination links
document.querySelectorAll('.page-link').forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const target = e.target.closest('a');
        window.scrollTo({
            top: 0,
            behavior: 'smooth',
        });
        window.location.href = target.href;
    });
});
