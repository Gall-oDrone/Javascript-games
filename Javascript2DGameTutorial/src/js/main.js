/**
 * Main entry point for the JavaScript 2D Game
 * Now includes loading screen, main menu, and leaderboard
 */
import { Game } from './game.js';

// Game initialization
window.addEventListener('load', function () {
    const canvas = document.getElementById('canvas1');
    const ctx = canvas.getContext('2d');

    // Set canvas dimensions
    canvas.width = 600;
    canvas.height = 600;

    // Set default context properties
    ctx.fillStyle = 'white';
    ctx.strokeStyle = 'white';
    ctx.lineWidth = 1;
    ctx.font = '30px Impact';

    // Initialize game with new systems
    const game = new Game(canvas);

    // Animation loop
    let lastTime = 0;
    function animate(timeStamp) {
        const deltaTime = timeStamp - lastTime;
        lastTime = timeStamp;

        // Clear canvas
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Render game based on current state
        game.render(ctx, deltaTime);

        // Continue animation loop
        requestAnimationFrame(animate);
    }

    // Start animation loop
    animate(0);

    // Add visibility change handler to pause when tab is not visible
    document.addEventListener('visibilitychange', function () {
        if (document.hidden) {
            if (game.gameState === 'playing') {
                game.pauseGame();
            }
        }
    });

    // Prevent default browser actions for game keys
    window.addEventListener('keydown', function (e) {
        // Prevent scrolling with arrow keys
        if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', ' '].includes(e.key)) {
            e.preventDefault();
        }
    });
});