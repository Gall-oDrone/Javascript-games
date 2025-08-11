/**
 * Main Menu System for JavaScript 2D Game
 * Provides menu navigation and game state management
 */
export class MainMenu {
    constructor(game) {
        this.game = game;
        this.selectedOption = 0;
        this.options = [
            { text: 'START GAME', action: 'start' },
            { text: 'LEADERBOARD', action: 'leaderboard' },
            { text: 'CONTROLS', action: 'controls' },
            { text: 'AI MODE', action: 'ai_toggle' }
        ];
        this.isActive = true;
        this.showLeaderboard = false;
        this.showControls = false;
        this.animationTime = 0;
        this.stars = this.generateStars();

        this.setupEventListeners();
    }

    generateStars() {
        const stars = [];
        for (let i = 0; i < 100; i++) {
            stars.push({
                x: Math.random() * this.game.width,
                y: Math.random() * this.game.height,
                size: Math.random() * 2 + 0.5,
                speed: Math.random() * 0.5 + 0.1,
                brightness: Math.random() * 0.5 + 0.5
            });
        }
        return stars;
    }

    setupEventListeners() {
        this.handleKeyDown = (e) => {
            if (!this.isActive) return;

            if (this.showLeaderboard || this.showControls) {
                if (e.key === 'Escape' || e.key === 'Enter') {
                    this.showLeaderboard = false;
                    this.showControls = false;
                }
                return;
            }

            switch (e.key) {
                case 'ArrowUp':
                    this.selectedOption = (this.selectedOption - 1 + this.options.length) % this.options.length;
                    break;
                case 'ArrowDown':
                    this.selectedOption = (this.selectedOption + 1) % this.options.length;
                    break;
                case 'Enter':
                case ' ':
                    this.selectOption();
                    break;
            }
        };

        window.addEventListener('keydown', this.handleKeyDown);
    }

    selectOption() {
        const option = this.options[this.selectedOption];

        switch (option.action) {
            case 'start':
                this.startGame();
                break;
            case 'leaderboard':
                this.showLeaderboard = true;
                break;
            case 'controls':
                this.showControls = true;
                break;
            case 'ai_toggle':
                this.toggleAIMode();
                break;
        }
    }

    startGame() {
        this.isActive = false;
        this.game.startGame();
    }

    toggleAIMode() {
        this.game.aiMode = !this.game.aiMode;
        // Update the menu option text
        const aiOption = this.options.find(opt => opt.action === 'ai_toggle');
        if (aiOption) {
            aiOption.text = this.game.aiMode ? 'AI MODE: ON' : 'AI MODE: OFF';
        }
    }

    activate() {
        this.isActive = true;
        this.selectedOption = 0;
        this.showLeaderboard = false;
        this.showControls = false;

        // Update AI mode text
        const aiOption = this.options.find(opt => opt.action === 'ai_toggle');
        if (aiOption) {
            aiOption.text = this.game.aiMode ? 'AI MODE: ON' : 'AI MODE: OFF';
        }
    }

    deactivate() {
        this.isActive = false;
    }

    update(deltaTime) {
        if (!this.isActive) return;

        this.animationTime += deltaTime;

        // Update stars
        this.stars.forEach(star => {
            star.y += star.speed;
            if (star.y > this.game.height) {
                star.y = -10;
                star.x = Math.random() * this.game.width;
            }

            // Twinkle effect
            star.brightness = 0.5 + Math.sin(this.animationTime * 0.001 + star.x) * 0.5;
        });
    }

    draw(context) {
        if (!this.isActive) return;

        // Clear background
        context.save();
        context.fillStyle = '#000011';
        context.fillRect(0, 0, this.game.width, this.game.height);

        // Draw stars
        this.stars.forEach(star => {
            context.fillStyle = `rgba(255, 255, 255, ${star.brightness})`;
            context.fillRect(star.x, star.y, star.size, star.size);
        });

        if (this.showLeaderboard) {
            this.drawLeaderboard(context);
        } else if (this.showControls) {
            this.drawControls(context);
        } else {
            this.drawMainMenu(context);
        }

        context.restore();
    }

    drawMainMenu(context) {
        // Title with glow effect
        context.save();

        // Glow effect
        context.shadowColor = '#00ff00';
        context.shadowBlur = 20 + Math.sin(this.animationTime * 0.002) * 10;

        // Main title
        context.fillStyle = '#00ff00';
        context.font = 'bold 48px Impact';
        context.textAlign = 'center';
        context.fillText('SPACE INVADERS', this.game.width / 2, 120);

        // Subtitle
        context.font = 'bold 20px Impact';
        context.fillStyle = '#ffff00';
        context.shadowBlur = 10;
        context.shadowColor = '#ffff00';
        context.fillText('WITH AI AGENT', this.game.width / 2, 150);

        // Reset shadow for menu options
        context.shadowBlur = 0;

        // Menu options
        const startY = 250;
        const optionSpacing = 50;

        this.options.forEach((option, index) => {
            const y = startY + (index * optionSpacing);
            const isSelected = index === this.selectedOption;

            // Selection indicator
            if (isSelected) {
                // Animated selection box
                const boxWidth = 300;
                const boxHeight = 40;
                const boxX = (this.game.width - boxWidth) / 2;
                const boxY = y - 25;

                context.strokeStyle = '#00ff00';
                context.lineWidth = 2;
                context.strokeRect(boxX, boxY, boxWidth, boxHeight);

                // Selection arrows
                const arrowOffset = Math.sin(this.animationTime * 0.003) * 10;
                context.fillStyle = '#00ff00';
                context.font = 'bold 24px Impact';
                context.fillText('▶', boxX - 30 - arrowOffset, y);
                context.fillText('◀', boxX + boxWidth + 15 + arrowOffset, y);
            }

            // Option text
            context.font = isSelected ? 'bold 28px Impact' : '24px Impact';
            context.fillStyle = isSelected ? '#ffffff' : '#888888';
            context.textAlign = 'center';
            context.fillText(option.text, this.game.width / 2, y);
        });

        // Instructions at bottom
        context.font = '14px Arial';
        context.fillStyle = '#666666';
        context.textAlign = 'center';
        context.fillText('Use ARROW KEYS to navigate | ENTER to select', this.game.width / 2, this.game.height - 30);

        // Version info
        context.font = '12px Arial';
        context.fillStyle = '#444444';
        context.textAlign = 'right';
        context.fillText('v1.0.0', this.game.width - 10, this.game.height - 10);

        context.restore();
    }

    drawLeaderboard(context) {
        // Draw leaderboard using the Leaderboard class
        if (this.game.leaderboard) {
            this.game.leaderboard.draw(
                context,
                (this.game.width - 500) / 2,
                50,
                500,
                450
            );

            // Back instruction
            context.fillStyle = '#00ff00';
            context.font = '16px Arial';
            context.textAlign = 'center';
            context.fillText('Press ESC or ENTER to return', this.game.width / 2, this.game.height - 50);
        }
    }

    drawControls(context) {
        const centerX = this.game.width / 2;
        const startY = 100;

        // Background box
        const boxWidth = 500;
        const boxHeight = 400;
        const boxX = (this.game.width - boxWidth) / 2;
        const boxY = 80;

        context.fillStyle = 'rgba(0, 0, 0, 0.8)';
        context.fillRect(boxX, boxY, boxWidth, boxHeight);

        context.strokeStyle = '#00ff00';
        context.lineWidth = 2;
        context.strokeRect(boxX, boxY, boxWidth, boxHeight);

        // Title
        context.fillStyle = '#00ff00';
        context.font = 'bold 28px Impact';
        context.textAlign = 'center';
        context.fillText('GAME CONTROLS', centerX, startY + 30);

        // Controls list
        const controls = [
            { key: 'ARROW KEYS', action: 'Move player ship' },
            { key: '1', action: 'Shoot projectile' },
            { key: '2', action: 'Small laser (uses energy)' },
            { key: '3', action: 'Big laser (uses more energy)' },
            { key: 'R', action: 'Restart game (when game over)' },
            { key: 'A', action: 'Toggle AI Agent' },
            { key: 'D', action: 'Change AI difficulty' },
            { key: 'ESC', action: 'Pause / Resume' }
        ];

        context.font = '16px monospace';
        context.textAlign = 'left';
        const listStartY = startY + 80;
        const lineHeight = 35;

        controls.forEach((control, index) => {
            const y = listStartY + (index * lineHeight);

            // Key
            context.fillStyle = '#ffff00';
            context.fillRect(boxX + 30, y - 15, 120, 25);
            context.fillStyle = '#000000';
            context.font = 'bold 14px monospace';
            context.textAlign = 'center';
            context.fillText(control.key, boxX + 90, y);

            // Action
            context.fillStyle = '#ffffff';
            context.font = '14px Arial';
            context.textAlign = 'left';
            context.fillText(control.action, boxX + 170, y);
        });

        // Back instruction
        context.fillStyle = '#00ff00';
        context.font = '16px Arial';
        context.textAlign = 'center';
        context.fillText('Press ESC or ENTER to return', centerX, this.game.height - 50);
    }

    cleanup() {
        window.removeEventListener('keydown', this.handleKeyDown);
    }
}

/**
 * Loading Screen for JavaScript 2D Game
 */
export class LoadingScreen {
    constructor(game) {
        this.game = game;
        this.progress = 0;
        this.maxProgress = 100;
        this.loadingText = 'LOADING';
        this.dots = '';
        this.dotTimer = 0;
        this.isComplete = false;
        this.assets = [];
        this.loadedAssets = 0;
        this.totalAssets = 0;
        this.fadeOut = false;
        this.fadeAlpha = 1;
    }

    addAsset(name, url) {
        this.assets.push({ name, url, loaded: false });
        this.totalAssets++;
    }

    loadAssets(callback) {
        if (this.totalAssets === 0) {
            this.isComplete = true;
            if (callback) callback();
            return;
        }

        let loadedCount = 0;

        this.assets.forEach(asset => {
            if (asset.url.includes('.png') || asset.url.includes('.jpg')) {
                const img = new Image();
                img.onload = () => {
                    asset.loaded = true;
                    loadedCount++;
                    this.loadedAssets = loadedCount;
                    this.progress = (loadedCount / this.totalAssets) * 100;

                    if (loadedCount === this.totalAssets) {
                        setTimeout(() => {
                            this.fadeOut = true;
                            setTimeout(() => {
                                this.isComplete = true;
                                if (callback) callback();
                            }, 500);
                        }, 500);
                    }
                };
                img.onerror = () => {
                    console.error(`Failed to load: ${asset.name}`);
                    loadedCount++;
                    this.loadedAssets = loadedCount;
                    this.progress = (loadedCount / this.totalAssets) * 100;

                    if (loadedCount === this.totalAssets) {
                        this.isComplete = true;
                        if (callback) callback();
                    }
                };
                img.src = asset.url;
            }
        });
    }

    update(deltaTime) {
        if (this.isComplete) return;

        // Animate dots
        this.dotTimer += deltaTime;
        if (this.dotTimer > 500) {
            this.dotTimer = 0;
            this.dots = this.dots.length >= 3 ? '' : this.dots + '.';
        }

        // Fade out animation
        if (this.fadeOut && this.fadeAlpha > 0) {
            this.fadeAlpha -= deltaTime * 0.002;
            if (this.fadeAlpha < 0) this.fadeAlpha = 0;
        }
    }

    draw(context) {
        if (this.isComplete && this.fadeAlpha <= 0) return;

        context.save();
        context.globalAlpha = this.fadeAlpha;

        // Background
        context.fillStyle = '#000011';
        context.fillRect(0, 0, this.game.width, this.game.height);

        // Loading text
        context.fillStyle = '#00ff00';
        context.font = 'bold 36px Impact';
        context.textAlign = 'center';
        context.fillText(this.loadingText + this.dots, this.game.width / 2, this.game.height / 2 - 50);

        // Progress bar background
        const barWidth = 400;
        const barHeight = 30;
        const barX = (this.game.width - barWidth) / 2;
        const barY = this.game.height / 2;

        context.strokeStyle = '#00ff00';
        context.lineWidth = 2;
        context.strokeRect(barX, barY, barWidth, barHeight);

        // Progress bar fill
        const fillWidth = (this.progress / this.maxProgress) * (barWidth - 4);
        if (fillWidth > 0) {
            const gradient = context.createLinearGradient(barX, 0, barX + fillWidth, 0);
            gradient.addColorStop(0, '#00ff00');
            gradient.addColorStop(1, '#00aa00');
            context.fillStyle = gradient;
            context.fillRect(barX + 2, barY + 2, fillWidth, barHeight - 4);
        }

        // Progress text
        context.fillStyle = '#ffffff';
        context.font = '18px monospace';
        context.fillText(`${Math.floor(this.progress)}%`, this.game.width / 2, barY + barHeight + 30);

        // Asset loading status
        if (this.totalAssets > 0) {
            context.font = '14px Arial';
            context.fillStyle = '#888888';
            context.fillText(`Loading assets: ${this.loadedAssets}/${this.totalAssets}`, this.game.width / 2, barY + barHeight + 60);
        }

        // Loading tips
        const tips = [
            'Use arrow keys to move your ship',
            'Press A to activate AI Agent',
            'Collect energy to use special weapons',
            'Higher waves mean tougher enemies'
        ];
        const tipIndex = Math.floor((this.progress / 100) * tips.length);
        if (tips[tipIndex]) {
            context.font = '12px Arial';
            context.fillStyle = '#666666';
            context.fillText(tips[tipIndex], this.game.width / 2, this.game.height - 50);
        }

        context.restore();
    }
}