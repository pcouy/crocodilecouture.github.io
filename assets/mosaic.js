if(!window.mosaic_init) {
    window.mosaic_init = true;
    let mosaics = document.querySelectorAll(".mosaic"); 
    mosaics.forEach(function(mosaic) {
        let overlay = mosaic.querySelector(".mosaic-overlay");
        let background = mosaic.querySelector(".overlay-background");
        console.log("overlay : ", overlay, "\n backgroud : ", background);
        background.addEventListener("click", ()=>overlay.classList.remove("show"));
        let images = mosaic.querySelectorAll(".mosaic-container img");
        let carousel = mosaic.querySelector("section.carousel");
        carousel.querySelector(".carousel-first").classList.add("hidden");
        images.forEach(function(image, index) {
            image.addEventListener("click", () => {
                carousel.goto_picture(index);
                overlay.classList.add("show");
            });
        });
    });
}
