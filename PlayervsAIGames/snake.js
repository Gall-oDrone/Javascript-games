class Snake {
    constructor(game, x, y, speedX, speedY){
        this.game = game;
        this.x = x;
        this.y = y;
        this.speedX = speedX;
        this.speedY = speedY;
    }
    update(){
        this.x += this.speedX;
        this.y += this.speedY;
    }
    draw(){
        this.game.ctx.fillStyle = 'blue';
        this.game.ctx.fillRect(this.x, this.y, 50, 20);
    }
}