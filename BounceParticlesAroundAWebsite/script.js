window.addEventListener('load', function() {
    const canvas = document.getElementById('canvas1');
    const ctx = canvas.getContext('2d');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    let gradient = ctx.createLinearGradient(0,0,0,canvas.height);
    gradient.addColorStop(0,'darkblue');
    gradient.addColorStop(0.5,'white');
    gradient.addColorStop(1,'lightblue');
    ctx.fillStyle = gradient;
    ctx.strokeStyle = 'white';
    // ctx.fillRect(50, 50, 100, 200);
    
    class Particle {
        constructor(effect){
            this.effect = effect;
            this.radius = Math.floor(Math.random() * 7 + 3);
            this.x = this.effect.heading.x + Math.random() * this.effect.heading.width;
            this.y = -this.radius - this.effect.maxDistance - Math.random() * this.effect.height * 0.2;
            this.vx = Math.random() * 2 - 1;
            this.vy = 0;
            this.gravity = this.radius * 0.001;
            this.friction = 0.95;
            this.width = this.radius * 2;
            this.height = this.radius * 2;
            this.bounced = 0;
        }
        draw(context){
            context.beginPath();
            context.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
            context.fill();
            if (this.effect.debug) {
                // context.strokeStyle = this.color;
                context.strokeRect(this.x - this.radius, this.y - this.radius, this.radius * 2, this.radius * 2);
            }
        }
        update(){
            this.vy += this.gravity;
            this.x += this.vx;
            this.y += this.vy;
    
            if (this.y > this.effect.height + this.radius + this.effect.maxDistance ||
                this.x < - this.radius - this.effect.maxDistance ||
                this.x > this.effect.width + this.radius + this.effect.maxDistance) {
                this.reset();
            }
    
            // collision detection
            if(
                this.x - this.radius < this.effect.heading.x + this.effect.heading.width &&
                this.x - this.radius + this.width > this.effect.heading.x &&
                this.y - this.radius < this.effect.heading.y + this.effect.heading.height &&
                this.height + this.y - this.radius > this.effect.heading.y &&
                this.bounced < 5
            ) {
                // Collision detected!
                this.vy *= -0.6;
                this.vx *= 2;
                this.y = this.effect.heading.y - this.radius;
                this.bounced++;
            }
        }
        reset(){
            this.x = this.effect.heading.x + Math.random() * this.effect.heading.width;
            this.y = -this.radius - this.effect.maxDistance - Math.random() * this.effect.height * 0.2;
            this.vy = 0;
            this.vx = Math.random() * 2 - 1;
            this.bounced = 0;
        }
    }
    
    class Effect{
        constructor(canvas, context){
            this.canvas = canvas;
            this.context = context;
            this.width = this.canvas.width;
            this.height = this.canvas.height;
            this.debug = true;
            this.element = document.getElementById('caption').
            getBoundingClientRect();
            this.canvasSize = this.canvas.getBoundingClientRect();
            this.heading = {
                x: this.element.x - this.canvasSize.x,
                y: this.element.y - this.canvasSize.y,
                width: this.element.width,
                height: this.element.height
            }
            this.particles = [];
            this.numberOfParticles = 100;
            this.maxDistance = 100;
            this.createParticles();
    
            this.mouse = {
                x: 0,
                y: 0,
                pressed: false,
                radius: 150
            }
    
            window.addEventListener('keydown', e => {
                if (e.key === 'd') {
                    this.debug = !this.debug;
                }
            })
            window.addEventListener('resize', e => {
                this.resize(e.target.window.innerWidth, e.target.window.innerHeight);
            });
            window.addEventListener('mousemove', e => {
                if (this.mouse.pressed){
                    this.mouse.x = e.x;
                    this.mouse.y = e.y;
                }
            });
            window.addEventListener('mousedown', e => {
                this.mouse.pressed = true;
            });
            window.addEventListener('mouseup', e => {
                this.mouse.pressed = false;
            });
        }
        createParticles(){
            for (let i = 0; i < this.numberOfParticles; i++) {
                this.particles.push(new Particle(this));
            }
        }
        handleParticles(context){
            context.fillStyle = gradient;
            this.connectParticles(context);
            this.particles.forEach(particle => {
                particle.draw(context);
                particle.update();
            });
            if (this.debug) {
                context.strokeRect(this.heading.x, this.heading.y, this.heading.width, this.heading.height)
            }
        }
        connectParticles(context){
            for (let a = 0; a < this.particles.length; a++) {
                for (let b = a; b < this.particles.length; b++) {
                    const dx = this.particles[a].x - this.particles[b].x;
                    const dy = this.particles[a].y - this.particles[b].y;
                    const distance = Math.hypot(dx, dy);
                    if (distance < this.maxDistance){
                        context.save();
                        const opacity = 1 - (distance/this.maxDistance);
                        context.globalAlpha = opacity;
                        context.beginPath();
                        context.moveTo(this.particles[a].x, this.particles[a].y);
                        context.lineTo(this.particles[b].x, this.particles[b].y);
                        context.stroke();
                        context.restore();
                    }
                }
            }
        }
        resize(width, height){
            this.canvas.width = width;
            this.canvas.height = height;
            this.width = width;
            this.height = height;
            this.element = document.getElementById('caption').
            getBoundingClientRect();
            this.canvasSize = this.canvas.getBoundingClientRect();
            this.heading = {
                x: this.element.x - this.canvasSize.x,
                y: this.element.y - this.canvasSize.y,
                width: this.element.width,
                height: this.element.height
            }
            gradient = this.context.createLinearGradient(0,0,canvas.width,canvas.height);
            gradient.addColorStop(0,'darkblue');
            gradient.addColorStop(0.5,'white');
            gradient.addColorStop(1,'lightblue');
            this.context.fillStyle = gradient;
            this.context.strokeStyle = 'white';
            this.particles.forEach(particle => {
                particle.reset();
            })
        }
    }
    
    const effect = new Effect(canvas, ctx);
    
    function animate(){
        // ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = 'rgba(0,0,0,0.05)'
        ctx.fillRect(0,0, canvas.widht, canvas.height);
        effect.handleParticles(ctx);
        requestAnimationFrame(animate);
    }
    animate();
})