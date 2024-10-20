// JavaScript to add fade-in animations when scrolling
document.addEventListener("DOMContentLoaded", function() {
    const fadeInElements = document.querySelectorAll(".fade-in");

    const options = {
        threshold: 0.1
    };

    const observer = new IntersectionObserver(function(entries, observer) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add("show");
                observer.unobserve(entry.target); 
            }
        });
    }, options);

    fadeInElements.forEach(element => {
        observer.observe(element);
    });
});
const localVersion = "1.0.0";

// Function to check for new versions
async function checkForNewVersion() {
    try {
        const response = await fetch('https://raw.githubusercontent.com/0xl30/Hyprland-Rice/main/yad/version.txt');
        const remoteVersion = await response.text();
        if (remoteVersion.trim() !== localVersion.trim()) {
            showUpdateNotification();
        }
    } catch (error) {
        console.error('Error checking for version updates:', error);
    }
}

// Function to display update notification
function showUpdateNotification() {
    const notification = document.createElement('div');
    notification.classList.add('update-notification');
    notification.innerHTML = `
        <p>New Version Available</p>
        <button id="show-update">Show Update</button>
        <button id="skip-update">Skip Update</button>
    `;
    document.body.appendChild(notification);
    document.getElementById('show-update').addEventListener('click', () => {
        fetchVersionDetails();
        notification.remove();
    });
    document.getElementById('skip-update').addEventListener('click', () => {
        notification.remove();
    });
}

// Function to fetch version.html and display the update details
async function fetchVersionDetails() {
    try {
        const response = await fetch('https://raw.githubusercontent.com/0xl30/Hyprland-Rice/master/yad/version.html');
        const versionContent = await response.text();
        const versionPopup = document.createElement('div');
        versionPopup.classList.add('version-popup');
        versionPopup.innerHTML = `
            <div class="version-popup-content">
                <button id="close-popup">Close</button>
                ${versionContent}
            </div>
        `;
        document.body.appendChild(versionPopup);

        // Close the popup
        document.getElementById('close-popup').addEventListener('click', () => {
            versionPopup.remove();
        });
    } catch (error) {
        console.error('Error fetching version details:', error);
    }
}


// Check for updates when the page loads
window.onload = () => {
    checkForNewVersion();
};
