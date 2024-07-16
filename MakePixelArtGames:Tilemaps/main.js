const GAME_WIDTH = 160;
const GAME_HEIGHT = 160;
const GAME_TILE = 32;
const ROWS = GAME_HEIGHT / GAME_TILE;
const COLUMNS = GAME_WIDTH / GAME_TILE;

const LEVEL1 = [
    9, 9, 9, 9, 9,
    1, 2, 2, 2, 3,
    6, 7, 7, 7, 8,
    6, 7, 7, 7, 8,
    11, 12, 12, 12, 13,
];

const LEVEL2 = [
    24, 24, 25, 24, 25,
    16, 12, 12, 12, 17,
    8, 14, 14, 14, 6,
    21, 2, 2, 2, 22,
    19, 20, 18, 19, 19,
];

const LEVEL3 = [
    5, 4, 7, 19, 7,
    14, 9, 7, 24, 21,
    14, 14, 14, 14, 14,
    19, 17, 16, 17, 22,
    24, 22, 21, 22, 18,
];

function getTile(map, col, row) {
    return map[row * COLUMNS + col];
}

window.addEventListener('load', function(){
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    canvas.width = GAME_WIDTH;
    canvas.height = GAME_HEIGHT;

    // canvas settings
    ctx.imageSmoothingEnabled = false;
    const TILE_IMAGE = document.getElementById('tilemap');
    const IMAGE_TILE = 32;
    const IMAGE_COLS = TILE_IMAGE.width / IMAGE_TILE;

    let debug = false;
    let level = LEVEL1;

    function drawLevel(level){
        for (let row = 0; row < ROWS; row++) {
            for (let col = 0; col < COLUMNS; col++){
                const tile = getTile(level, col, row);
                ctx.drawImage(
                    TILE_IMAGE, 
                    ((tile - 1) * IMAGE_TILE) % TILE_IMAGE.width,
                    Math.floor((tile - 1) / IMAGE_COLS) * IMAGE_TILE,
                    IMAGE_TILE,
                    IMAGE_TILE,
                    col * GAME_TILE, 
                    row * GAME_TILE,
                    GAME_TILE,
                    GAME_TILE
                );
                if (debug) {
                    ctx.strokeRect(col * GAME_TILE, row * GAME_TILE, GAME_TILE, GAME_TILE)
                }
            }
        }
    }
    drawLevel(level);

    // controls
    const debugButton = document.getElementById('debugbutton');
    const level1button = document.getElementById('level1button');
    const level2button = document.getElementById('level2button');
    const level3button = document.getElementById('level3button');
    
    debugButton.addEventListener('click', function() {
        debug = !debug;
        drawLevel(level);
    });

    level1button.addEventListener('click', function(){
        level = LEVEL1;
        drawLevel(level);
    });
    level2button.addEventListener('click', function(){
        level = LEVEL2;
        drawLevel(level);
    });
    level3button.addEventListener('click', function(){
        level = LEVEL3;
        drawLevel(level);
    });
})