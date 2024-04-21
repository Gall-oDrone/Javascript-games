window.addEventListener('load', function(){
    const canvas = document.getElementById('canvas1');
    const ctx = canvas.getContext('2d');
    canvas.width = 600;
    canvas.height = 800;
    ctx.strokeStyle = "white";
    ctx.lineWidth = 3;

    class Asteroid {
        constructor(game){
            this.game = game;
            this.radius = 75;
            this.x = -this.radius;
            this.y = Math.random() * this.game.height;
            this.image = document.getElementById('asteroid');
            this.spriteWidth = 150;
            this.spriteHeight = 155;
            this.speed = Math.random() * 1.5 + 0.1;
            this.free = true;
            this.angle = 0;
            this.va = Math.random() * 0.2 - 0.01;
        }
        draw(context) {
            if (!this.free) {
                // context.beginPath();
                // context.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
                // context.stroke();
                context.save();
                context.translate(this.x, this.y);
                context.rotate(this.angle);
                context.drawImage(this.image, 0 - this.spriteWidth * 0.5, 0 - this.spriteHeight * 0.5);
                context.restore();
            }
        }
        update(){
            this.angle += this.va;
            if (!this.free) {
                this.x += this.speed;
                if (this.x > this.game.width + this.radius){
                    this.reset();
                }
            }
        }
        reset() {
            this.free = true;
        }
        start(){
            this.free = false;
            this.x = -this.radius;
            this.y = Math.random() * this.game.height;
        }
    }

    class Game {
        constructor(width, height){
            this.width = width;
            this.height = height;
            this.asteroidPool = [];
            this.max = 3;
            this.asteriodTimer = 0;
            this.asteroidInterval = 1000;
            this.createasteroidPool();
        }
        createasteroidPool(){
            for (let i = 0; i < this.max; i++){
                this.asteroidPool.push(new Asteroid(this));
            }
        }
        getElement(){
            for (let i = 0; i < this.asteroidPool.length; i++) {
                if (this.asteroidPool[i].free){
                    return this.asteroidPool[i];
                };
                
            }
        }
        render(context, deltaTime) {
            // create asteriod periodically
            if (this.asteriodTimer > this.asteroidInterval) {
                const asteriod = this.getElement();
                if(asteriod) asteriod.start();
                // add new Asteriod
                this.asteriodTimer = 0;
            } else {
                this.asteriodTimer += deltaTime
            }
            this.asteroidPool.forEach(asteroid => {
                asteroid.draw(context);
                asteroid.update();
            });
        }
    }

    const game = new Game(canvas.width, canvas.height);
    
    let lastTime = 0;
    function animate(timeStamp) {
        const deltaTime = timeStamp - lastTime;
        lastTime = timeStamp;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        game.render(ctx, deltaTime);
        requestAnimationFrame(animate);
    }
    animate(0);
})