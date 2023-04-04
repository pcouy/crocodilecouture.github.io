if (!window.carousel_init) {
    console.log("Carousel init:",window.carousel_init);
    window.carousel_init = true;
    let carousels = document.querySelectorAll(".carousel");
    console.log(carousels);
    carousels.forEach(function(carousel){
        let carousel_pictures = carousel.querySelectorAll(".carousel-container picture");
        let wrapped_pictures = Array.from(carousel_pictures).map(img => {
            img.remove();
            console.log("Removed :",img);
            let figure = document.createElement("figure");
            let caption = document.createElement("figcaption");
            caption.innerText = img.querySelector("img").alt;
            figure.append(img);
            figure.append(caption);
            return figure;
        });
        let placeholder = document.createElement("figure");
        placeholder.classList.add("carousel-placeholder");

        let carousel_p = carousel.querySelector(".carousel-container>p");
        if (carousel_p) carousel_p.remove();
        let carousel_container = carousel.getElementsByClassName("carousel-container")[0];

        let carousel_preload = document.createElement("div");
        Object.assign(carousel_preload.style, {
            position: "fixed",
            top: "-100px",
            left: "-100px",
            width: "10px",
            height: "10px",
            overflow: "hidden",
            opacity: 0.01
        });
        carousel.append(carousel_preload);

        let current_index = 0;
        let init = false;
        let running = false;

        let update_dom = (e) => {
            if (running) return;
            running = true;

            let previous_index = current_index;
            let direction = 'next';
            if (e !== undefined) {
                classes = e.target.classList;
                if (classes.contains("carousel-next")) {
                    current_index = Math.min(current_index + 1, wrapped_pictures.length - 1);
                    direction = 'next';
                }else if (classes.contains("carousel-prev")) {
                    current_index = Math.max(0, current_index - 1);
                    direction = 'prev';
                }
            }

            if (current_index === 0) {
                carousel.querySelectorAll(".carousel-prev").forEach(button=>{
                    button.classList.add("hide")
                });
            } else {
                carousel.querySelectorAll(".carousel-prev").forEach(button=>{
                    button.classList.remove("hide")
                });
            }

            if (current_index === wrapped_pictures.length - 1) {
                carousel.querySelectorAll(".carousel-next").forEach(button=>{
                    button.classList.add("hide")
                });
            } else {
                carousel.querySelectorAll(".carousel-next").forEach(button=>{
                    button.classList.remove("hide")
                });
            }

            let animation_class = (direction === "next" ? "left-animated" : "right-animated");
            let other_animation_class = (direction === "prev" ? "left-animated" : "right-animated");
            carousel_container.classList.remove(animation_class, "animation-part2");
            
            let add_pic = (picture) => {
                if (direction === "next") {
                    carousel_container.append(picture);
                } else if (direction === "prev") {
                    carousel_container.prepend(picture);
                }
            }

            let entering_pic = null;
            let leaving_pic = null;

            if (direction === "next") {
                if (current_index === 1) leaving_pic = placeholder;
                else if (current_index === wrapped_pictures.length-1) entering_pic = placeholder;
            } else {
                if (current_index === 0) entering_pic = placeholder;
                else if (current_index === wrapped_pictures.length-2) leaving_pic = placeholder;
            }
            if(!init) carousel_container.append(placeholder);

            wrapped_pictures.forEach((picture, index) => {
                if (Math.abs(current_index - index) < 2) {
                    // Picture should be in DOM
                    if (!carousel_container.contains(picture)) {
                        // Picture is entering the DOM
                        entering_pic = picture;
                        carousel_preload.append(entering_pic);
                        if (!init) add_pic(picture);
                    }
                }else{
                    // Picture should not be in DOM
                    if (carousel_container.contains(picture)) {
                        // Picture is leaving the DOM
                        leaving_pic = picture;
                    } else if (Math.abs(current_index - index) == 2) {
                        carousel_preload.append(picture);
                    }
                }

                if (index == current_index) {
                    picture.classList.add("carousel-active");
                } else if (picture.classList.contains("carousel-active")) {
                    picture.classList.remove("carousel-active");
                }
            });

            if (init && previous_index === current_index) {
                running = false
                return;
            }
            if (init) {
                carousel_container.classList.add(animation_class);
                let animation_phase = 1;
                let animation_cb = ()=>{
                    console.log("animation phase", animation_phase);
                    if (animation_phase === 1) {
                        //carousel_container.classList.remove(animation_class);
                        if (leaving_pic) leaving_pic.remove()
                        if (entering_pic) add_pic(entering_pic);
                        carousel_container.classList.add(other_animation_class, "animation-part2");
                        carousel_container.classList.remove(animation_class);
                    } else {
                        carousel_container.classList.remove(other_animation_class, animation_class, "animation-part2");
                        running = false;
                        carousel_container.removeEventListener("animationend", animation_cb);
                    }
                    animation_phase++;


                }
                carousel_container.addEventListener("animationend", animation_cb);
            }

            carousel.querySelectorAll("img").forEach(i=>i.loading = "eager");
            if (!init) running = false;
            init = true;
        };

        carousel.querySelectorAll(".carousel-next,.carousel-prev").forEach(control => {
            control.addEventListener("click", update_dom);
        });
        update_dom();
    });
}
