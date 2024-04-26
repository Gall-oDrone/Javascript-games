class Game {
    constructor(canvas, context){
        this.canvas = canvas;
        this.ctx = context;
        this.width = this.canvas.width;
        this.height = this.canvas.height;
        this.snake = new Snake(this, 0 ,0, 1, 1);
        this.cellSize = 50;
        this.columns = this.width / this.cellSize;
        this.rows = this.height / this.cellSize;

        window.addEventListener('resize', e => {
            this.canvas.width = e.currentTarget.innerWidth;
            this.resize(e.currentTarget.innerWidth, e.currentTarget.innerHeight);
        })
    }
    resize(width, height){
        this.canvas.width = Math.floor(width);
        this.canvas.height = Math.floor(height);
        this.ctx.fillStyle = 'blue';
        this.width = this.canvas.width;
        this.height = this.canvas.height;
        this.render();
    }
    drawGrid(){
        for (let y = 0; y < this.rows; y++){
            for (let x = 0; x < this.columns; x++) {
                this.ctx.strokeRect(x * this.cellSize, y * this.cellSize, this.cellSize, this.cellSize);
            }
        }
    }
    render(){
        this.drawGrid();
        // this.snake.update();
        // this.snake.draw();
    }
}

window.addEventListener('load', function(){
    const canvas = this.document.getElementById('canvas1');
    const ctx = canvas.getContext('2d');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    const game = new Game(canvas, ctx);

    function animate(){
        ctx.clearRect(0,0,canvas.width,canvas.height);
        game.render();
        requestAnimationFrame(animate);
    }
    requestAnimationFrame(animate);
});