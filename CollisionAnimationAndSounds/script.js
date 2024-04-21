window.addEventListener('load', function(){
    const canvas = document.getElementById('canvas1');
    const ctx = canvas.getContext('2d');
    canvas.width = 600;
    canvas.height = 800;
    ctx.strokeStyle = "white";
    ctx.lineWidth = 3;
    ctx.font = "20px Helvetica";
    ctx.fillStyle = "white";

    class Asteroid {
        constructor(game){
            this.game = game;
            this.radius = 75;
            this.x = -this.radius;
            this.y = Math.random() * this.game.height;
            this.image = document.getElementById('asteroid');
            this.spriteWidth = 150;
            this.spriteHeight = 155;
            this.speed = Math.random() * 5 + 2;
            this.free = true;
            this.angle = 0;
            this.va = Math.random() * 0.02 - 0.01;
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
            if (!this.free){
                this.angle += this.va;
                if (!this.free) {
                    this.x += this.speed;
                    if (this.x > this.game.width - this.radius){
                        this.reset();
                        const explosion = this.game.getExplosion();
                        if (explosion) explosion.start(this.x, this.y, 0);
                    }
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

    class Explosion {
        constructor(game) {
            this.game = game;
            this.x = 0;
            this.y = 0;
            this.speed = 0;
            this.image = document.getElementById('explosions');
            this.spriteWidth = 300;
            this.spriteHeight = 300;
            this.free = true;
            this.frameX = 0;
            this.frameY = Math.floor(Math.random() * 3);
            this.maxFrame = 22;
            this.animationTimer = 0;
            this.animationInterval = 1000/25;
            this.sound = this.game.explosionSounds[Math.floor(Math.random() * 
                this.game.explosionSounds.length)];
        }
        draw(context){
            if (!this.free) {
                context.drawImage(this.image, 
                    this.spriteWidth * this.frameX, 
                    this.spriteHeight * this.frameY, 
                    this.spriteWidth,
                    this.spriteHeight, 
                    this.x - this.spriteWidth * 0.5, 
                    this.y - this.spriteHeight * 0.5, 
                    this.spriteWidth,
                    this.spriteHeight);
            }
        }
        update(deltaTime){
            if (!this.free) {
                this.x += this.speed;
                if (this.animationTimer > this.animationInterval){
                    this.frameX++;
                    if (this.frameX > this.maxFrame) this.reset();
                    this.animationTimer = 0;
                } else {
                    this.animationTimer += deltaTime;
                }
            }
        }
        play(){
            this.sound.currentTime = 0;
            this.sound.play();
        }
        reset(){
            this.free = true;
        }
        start(x, y, speed){
            this.free = false;
            this.x = x;
            this.y = y;
            this.frameX = 0;
            this.speed = speed;
            this.play();
        }
    }

    class Game {
        constructor(width, height){
            this.width = width;
            this.height = height;
            this.asteroidPool = [];
            this.maxAsteriods = 3;
            this.asteriodTimer = 0;
            this.asteroidInterval = 1000/25;
            this.createAsteroidPool();
            this.score = 0;
            this.maxScore = 2;
            this.mouse = {
                x: 0,
                y: 0,
                radius: 2,
            }
            this.explosion1 = document.getElementById("explosion1");
            this.explosion2 = document.getElementById("explosion2");
            this.explosion3 = document.getElementById("explosion3");
            this.explosion4 = document.getElementById("explosion4");
            this.explosion5 = document.getElementById("explosion5");
            this.explosion6 = document.getElementById("explosion6");
            this.explosionSounds = [this.explosion1,this.explosion2,this.explosion3,
                this.explosion4,this.explosion5,this.explosion6];
            this.explosionPool = [];
            this.maxExplosions = 5;
            this.createExplosionPool();

            window.addEventListener('click', e => {
                // add explosion at click coordinates
                this.mouse.x = e.offsetX;
                this.mouse.y = e.offsetY;
                this.asteroidPool.forEach(asteriod => {
                    if (!asteriod.free && this.checkCollision(asteriod, this.mouse))
                    {
                        const explosion = this.getExplosion();
                        if (explosion) explosion.start(asteriod.x, asteriod.y, asteriod.speed * 0.4);
                        asteriod.reset();
                        if (this.score < this.maxScore) this.score++;
                    }
                });
            });
        }
        createAsteroidPool(){
            for (let i = 0; i < this.maxAsteriods; i++){
                this.asteroidPool.push(new Asteroid(this));
            }
        }
        createExplosionPool(){
            for (let i = 0; i < this.maxExplosions; i++){
                this.explosionPool.push(new Explosion(this));
            }
        }
        getAsteriod(){
            for (let i = 0; i < this.asteroidPool.length; i++) {
                if (this.asteroidPool[i].free){
                    return this.asteroidPool[i];
                };
                
            }
        }
        getExplosion(){
            for (let i = 0; i < this.explosionPool.length; i++) {
                if (this.explosionPool[i].free){
                    return this.explosionPool[i];
                };
                
            }
        }
        checkCollision(a, b){
            const sumOfRadii = a.radius + b.radius;
            const dx = a.x - b.x;
            const dy = a.y - b.y;
            const distance = Math.hypot(dx, dy);
            return distance < sumOfRadii;
        }
        render(context, deltaTime) {
            // create asteriod periodically
            if (this.asteriodTimer > this.asteroidInterval) {
                const asteriod = this.getAsteriod();
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
            this.explosionPool.forEach(explosion => {
                explosion.draw(context);
                explosion.update(deltaTime);
            });
            context.fillText("Score: " + this.score, 20, 35);
            if (this.score >= this.maxScore) {
                context.save();
                context.textAlign = 'center';
                context.fillText("You, win, final score: " + this.score, this.width * 0.5, this.height * 0.5);
                context.restore();
            }
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