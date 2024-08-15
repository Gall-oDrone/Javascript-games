import { Hero } from "./scripts/hero.js";
import { Input } from "./scripts/input.js";
import { World } from "./scripts/world.js";

export const TILE_SIZE = 32;
export const COLS = 15;
export const ROWS = 20;
const GAME_WIDTH = TILE_SIZE * COLS;
const GAME_HEIGHT = TILE_SIZE * ROWS;
export const HALF_TILE = TILE_SIZE / 2;

window.addEventListener('load', function(){
    const canvas = document.getElementById('canvas1')
    const ctx = canvas.getContext('2d');
    canvas.width = GAME_WIDTH;
    canvas.height = GAME_HEIGHT;
    console.log("document.getElementById('hero1'): ", document.getElementById('hero1'))
    class Game {
        constructor() {
            this.world = new World();
            this.hero = new Hero({
                game: this,
                sprite: {
                    image: document.getElementById('hero1'),
                    x:0,
                    y:11,
                    width:64,
                    height:64
                },
                position: {x: 1 * TILE_SIZE, y: 2 * TILE_SIZE},
                scale: 1,
            });
            this.input = new Input();

            this.eventUpdate = false;
            this.eventTimer = 0;
            this.eventInterval = 200;
        }
        render(ctx, deltaTime) {
            this.hero.update(deltaTime);
            this.world.drawBackground(ctx);
            this.world.drawGrid(ctx);
            this.hero.draw(ctx);
            this.world.drawForeground(ctx);

            if (this.eventTimer < this.eventInterval) {
                this.eventTimer += deltaTime;
                this.eventUpdate = false;
            } else {
                this.eventTimer = 0;
                this.eventUpdate = true;
            }
        }
    }

    const game = new Game();

    let lastTime = 0;
    function animate(timeStamp){
        requestAnimationFrame(animate);
        const deltaTime = timeStamp - lastTime;
        lastTime = timeStamp;
        game.render(ctx, deltaTime);
    }
    this.requestAnimationFrame(animate);
})