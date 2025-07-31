/**
 * Main entry point for the JavaScript 2D Game
 */
import { Game } from './Game.js';

// Game initialization
window.addEventListener('load', function() {
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

    // Initialize game
    const game = new Game(canvas);

    // Animation loop
    let lastTime = 0;
    function animate(timeStamp) {
        const deltaTime = timeStamp - lastTime;
        lastTime = timeStamp;
        
        // Clear canvas
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        // Render game
        game.render(ctx, deltaTime);
        
        // Continue animation loop
        requestAnimationFrame(animate);
    }
    
    // Start animation loop
    animate(0);
}); 