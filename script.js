function scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        section.scrollIntoView({
            behavior: 'smooth' // Pour un défilement doux
        });
    } else {
        console.error(`Section with ID '${sectionId}' not found.`);
    }
}

// Optionnel : Si vous avez d'autres scripts ou un écouteur de DOMContentLoaded
document.addEventListener('DOMContentLoaded', () => {
    // Si votre fonction est encapsulée ou dépend du chargement du DOM
    // assurez-vous qu'elle est accessible globalement ou que l'événement est attaché ici.
});