export class InputHandler {
    constructor(game) {
        this.game = game;
        this.keys = [];
        this.lastKey = '';
        window.addEventListener('keydown', (e) => {
            switch(e.key){
                case "ArrowLeft":
                    this.lastKey = "PRESS left";
                    break
                case "ArrowRight":
                    this.lastKey = "PRESS right";
                    break
                case "ArrowDown":
                    this.lastKey = "PRESS down";
                    break
                case "ArroUp":
                    this.lastKey = "PRESS up";
                    break
            }
            if(e.key === 'd') this.game.debug !this.game.debug;
        });
        window.addEventListener('keyup', (e) => {
            switch(e.key){
                case "ArrowLeft":
                    this.lastKey = "RELEASE left";
                    break
                case "ArrowRight":
                    this.lastKey = "RELEASE right";
                    break
                case "ArrowDown":
                    this.lastKey = "RELEASE down";
                    break
                case "ArroUp":
                    this.lastKey = "RELEASE up";
                    break
            }
        })
    }
}