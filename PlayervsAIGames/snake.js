class Snake {
    constructor(game, x, y, speedX, speedY, color){
        this.game = game;
        this.x = x;
        this.y = y;
        this.speedX = speedX;
        this.speedY = speedY;
        this.color = color;
        this.width = this.game.cellSize;
        this.height = this.game.cellSize;
    }
    update(){
        this.x += this.speedX;
        this.y += this.speedY;
    }
    draw(){
        this.game.ctx.fillStyle = this.color;
        this.game.ctx.fillRect(this.x * this.game.cellSize, this.y * this.game.cellSize, this.game.cellSize, this.width, this.height);
    }
}