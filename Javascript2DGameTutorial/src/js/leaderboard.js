/**
 * Leaderboard System for JavaScript 2D Game
 * Manages high scores and player aliases
 */
export class Leaderboard {
    constructor() {
        this.maxEntries = 10;
        this.maxAliasLength = 12;
        this.storageKey = 'javascript2DGameLeaderboard';
        this.scores = this.loadScores();
    }

    /**
     * Load scores from localStorage
     */
    loadScores() {
        try {
            const stored = localStorage.getItem(this.storageKey);
            if (stored) {
                const scores = JSON.parse(stored);
                // Validate and clean data
                return scores.filter(entry =>
                    entry &&
                    typeof entry.alias === 'string' &&
                    typeof entry.score === 'number' &&
                    typeof entry.wave === 'number' &&
                    entry.date
                ).slice(0, this.maxEntries);
            }
        } catch (error) {
            console.error('Error loading leaderboard:', error);
        }
        return this.getDefaultScores();
    }

    /**
     * Get default high scores
     */
    getDefaultScores() {
        return [
            { alias: "ACE", score: 5000, wave: 15, date: new Date().toISOString() },
            { alias: "PILOT", score: 4500, wave: 14, date: new Date().toISOString() },
            { alias: "HERO", score: 4000, wave: 13, date: new Date().toISOString() },
            { alias: "STAR", score: 3500, wave: 12, date: new Date().toISOString() },
            { alias: "NOVA", score: 3000, wave: 11, date: new Date().toISOString() },
            { alias: "COMET", score: 2500, wave: 10, date: new Date().toISOString() },
            { alias: "ROCKET", score: 2000, wave: 9, date: new Date().toISOString() },
            { alias: "BLAZE", score: 1500, wave: 8, date: new Date().toISOString() },
            { alias: "SPARK", score: 1000, wave: 7, date: new Date().toISOString() },
            { alias: "ROOKIE", score: 500, wave: 5, date: new Date().toISOString() }
        ];
    }

    /**
     * Save scores to localStorage
     */
    saveScores() {
        try {
            localStorage.setItem(this.storageKey, JSON.stringify(this.scores));
            return true;
        } catch (error) {
            console.error('Error saving leaderboard:', error);
            return false;
        }
    }

    /**
     * Check if score qualifies for leaderboard
     */
    isHighScore(score) {
        if (this.scores.length < this.maxEntries) {
            return true;
        }
        return score > this.scores[this.scores.length - 1].score;
    }

    /**
     * Add new score to leaderboard
     */
    addScore(alias, score, wave) {
        // Validate and sanitize alias
        alias = this.sanitizeAlias(alias);

        if (!alias || score <= 0) {
            return false;
        }

        const newEntry = {
            alias: alias,
            score: score,
            wave: wave,
            date: new Date().toISOString()
        };

        // Add to scores array
        this.scores.push(newEntry);

        // Sort by score (descending)
        this.scores.sort((a, b) => b.score - a.score);

        // Keep only top entries
        this.scores = this.scores.slice(0, this.maxEntries);

        // Save to localStorage
        return this.saveScores();
    }

    /**
     * Sanitize player alias
     */
    sanitizeAlias(alias) {
        if (!alias) return '';

        // Convert to uppercase, remove special characters, limit length
        return alias
            .toUpperCase()
            .replace(/[^A-Z0-9\s]/g, '')
            .trim()
            .substring(0, this.maxAliasLength);
    }

    /**
     * Get formatted leaderboard for display
     */
    getFormattedScores() {
        return this.scores.map((entry, index) => ({
            rank: index + 1,
            alias: entry.alias,
            score: entry.score,
            wave: entry.wave,
            date: entry.date
        }));
    }

    /**
     * Get player's rank for a given score
     */
    getRank(score) {
        const rank = this.scores.findIndex(entry => score > entry.score);
        return rank === -1 ? this.scores.length + 1 : rank + 1;
    }

    /**
     * Clear all scores (reset leaderboard)
     */
    clearScores() {
        this.scores = this.getDefaultScores();
        this.saveScores();
    }

    /**
     * Draw leaderboard on canvas
     */
    draw(context, x, y, width, height, currentScore = null) {
        // Background
        context.save();
        context.fillStyle = 'rgba(0, 0, 0, 0.8)';
        context.fillRect(x, y, width, height);

        // Border
        context.strokeStyle = '#00ff00';
        context.lineWidth = 2;
        context.strokeRect(x, y, width, height);

        // Title
        context.fillStyle = '#00ff00';
        context.font = 'bold 24px Impact';
        context.textAlign = 'center';
        context.fillText('LEADERBOARD', x + width / 2, y + 35);

        // Headers
        context.font = 'bold 16px Impact';
        context.fillStyle = '#ffff00';
        const headerY = y + 65;
        context.textAlign = 'left';
        context.fillText('RANK', x + 20, headerY);
        context.fillText('NAME', x + 80, headerY);
        context.textAlign = 'right';
        context.fillText('WAVE', x + width - 80, headerY);
        context.fillText('SCORE', x + width - 20, headerY);

        // Separator line
        context.strokeStyle = '#00ff00';
        context.lineWidth = 1;
        context.beginPath();
        context.moveTo(x + 10, headerY + 5);
        context.lineTo(x + width - 10, headerY + 5);
        context.stroke();

        // Scores
        context.font = '14px monospace';
        const scores = this.getFormattedScores();
        const lineHeight = 25;
        const startY = headerY + 30;

        scores.forEach((entry, index) => {
            const scoreY = startY + (index * lineHeight);

            // Highlight current score if it matches
            if (currentScore && entry.score === currentScore) {
                context.fillStyle = 'rgba(255, 255, 0, 0.2)';
                context.fillRect(x + 10, scoreY - 15, width - 20, 20);
            }

            // Rank colors
            if (entry.rank === 1) context.fillStyle = '#ffd700'; // Gold
            else if (entry.rank === 2) context.fillStyle = '#c0c0c0'; // Silver
            else if (entry.rank === 3) context.fillStyle = '#cd7f32'; // Bronze
            else context.fillStyle = '#ffffff';

            // Draw entry
            context.textAlign = 'left';
            context.fillText(`#${entry.rank}`, x + 20, scoreY);
            context.fillText(entry.alias, x + 80, scoreY);

            context.textAlign = 'right';
            context.fillText(entry.wave.toString(), x + width - 80, scoreY);
            context.fillText(entry.score.toLocaleString(), x + width - 20, scoreY);
        });

        context.restore();
    }
}

/**
 * Alias Input Handler for entering player name
 */
export class AliasInput {
    constructor(game) {
        this.game = game;
        this.isActive = false;
        this.alias = '';
        this.maxLength = 12;
        this.cursorBlink = 0;
        this.cursorVisible = true;
        this.callback = null;
        this.score = 0;
        this.wave = 0;

        this.setupEventListeners();
    }

    setupEventListeners() {
        this.handleKeyPress = (e) => {
            if (!this.isActive) return;

            if (e.key === 'Enter') {
                this.submit();
            } else if (e.key === 'Backspace') {
                e.preventDefault();
                this.alias = this.alias.slice(0, -1);
            } else if (e.key === 'Escape') {
                this.cancel();
            } else if (e.key.length === 1 && this.alias.length < this.maxLength) {
                // Only allow letters, numbers, and spaces
                if (/^[a-zA-Z0-9\s]$/.test(e.key)) {
                    this.alias += e.key.toUpperCase();
                }
            }
        };
    }

    activate(score, wave, callback) {
        this.isActive = true;
        this.alias = '';
        this.score = score;
        this.wave = wave;
        this.callback = callback;
        this.cursorBlink = 0;

        // Add event listener
        window.addEventListener('keydown', this.handleKeyPress);
    }

    deactivate() {
        this.isActive = false;
        window.removeEventListener('keydown', this.handleKeyPress);
    }

    submit() {
        if (this.alias.trim().length > 0) {
            if (this.callback) {
                this.callback(this.alias.trim());
            }
            this.deactivate();
        }
    }

    cancel() {
        if (this.callback) {
            this.callback(null);
        }
        this.deactivate();
    }

    update(deltaTime) {
        if (!this.isActive) return;

        // Cursor blinking
        this.cursorBlink += deltaTime;
        if (this.cursorBlink > 500) {
            this.cursorVisible = !this.cursorVisible;
            this.cursorBlink = 0;
        }
    }

    draw(context) {
        if (!this.isActive) return;

        const width = 400;
        const height = 200;
        const x = (this.game.width - width) / 2;
        const y = (this.game.height - height) / 2;

        // Background
        context.save();
        context.fillStyle = 'rgba(0, 0, 0, 0.9)';
        context.fillRect(x, y, width, height);

        // Border
        context.strokeStyle = '#00ff00';
        context.lineWidth = 3;
        context.strokeRect(x, y, width, height);

        // Title
        context.fillStyle = '#00ff00';
        context.font = 'bold 24px Impact';
        context.textAlign = 'center';
        context.fillText('NEW HIGH SCORE!', x + width / 2, y + 40);

        // Score info
        context.fillStyle = '#ffff00';
        context.font = '18px Impact';
        context.fillText(`Score: ${this.score.toLocaleString()} | Wave: ${this.wave}`, x + width / 2, y + 70);

        // Instructions
        context.fillStyle = '#ffffff';
        context.font = '14px Arial';
        context.fillText('Enter your name (max 12 characters):', x + width / 2, y + 100);

        // Input field
        const inputY = y + 130;
        const inputWidth = 300;
        const inputHeight = 40;
        const inputX = x + (width - inputWidth) / 2;

        // Input background
        context.fillStyle = 'rgba(255, 255, 255, 0.1)';
        context.fillRect(inputX, inputY, inputWidth, inputHeight);

        // Input border
        context.strokeStyle = '#ffffff';
        context.lineWidth = 2;
        context.strokeRect(inputX, inputY, inputWidth, inputHeight);

        // Input text
        context.fillStyle = '#ffffff';
        context.font = 'bold 20px monospace';
        context.textAlign = 'left';
        const textX = inputX + 10;
        const textY = inputY + inputHeight / 2 + 7;
        context.fillText(this.alias, textX, textY);

        // Cursor
        if (this.cursorVisible) {
            const textWidth = context.measureText(this.alias).width;
            context.fillRect(textX + textWidth + 2, inputY + 8, 2, inputHeight - 16);
        }

        // Character count
        context.fillStyle = '#888888';
        context.font = '12px Arial';
        context.textAlign = 'right';
        context.fillText(`${this.alias.length}/${this.maxLength}`, inputX + inputWidth - 5, inputY - 5);

        // Submit instructions
        context.fillStyle = '#00ff00';
        context.font = '14px Arial';
        context.textAlign = 'center';
        context.fillText('Press ENTER to submit | ESC to cancel', x + width / 2, y + height - 20);

        context.restore();
    }
}