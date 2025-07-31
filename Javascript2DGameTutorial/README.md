# JavaScript 2D Game Tutorial with AI Agent

A modern Space Invaders-style 2D game built with vanilla JavaScript, featuring an intelligent AI agent and comprehensive deployment infrastructure.

## 🎮 Game Features

- **Classic Space Invaders gameplay** with modern JavaScript
- **AI Agent** with multiple difficulty levels (Easy/Medium/Hard)
- **Multiple enemy types** (Beetlemorph, Rhinomorph, Boss)
- **Weapon system** (Projectiles, Small Laser, Big Laser)
- **Wave-based progression** with increasing difficulty
- **Energy management system** for special weapons
- **Responsive controls** and smooth animations

## 🏗️ Project Structure

```
Javascript2DGameTutorial/
├── src/                          # Source code
│   ├── js/                       # JavaScript modules
│   │   ├── classes/              # Game object classes
│   │   │   ├── Player.js         # Player ship class
│   │   │   ├── Enemy.js          # Enemy base and subclasses
│   │   │   ├── Boss.js           # Boss enemy class
│   │   │   ├── Projectile.js     # Player bullets
│   │   │   ├── Lasers.js         # Laser weapon classes
│   │   │   └── Wave.js           # Enemy wave management
│   │   ├── Game.js               # Main game orchestrator
│   │   ├── main.js               # Application entry point
│   │   └── ai-agent.js           # AI agent implementation
│   ├── css/                      # Stylesheets
│   │   └── game.css              # Game styling
│   └── assets/                   # Game assets
│       ├── images/               # Image assets
│       ├── audio/                # Audio files
│       └── fonts/                # Custom fonts
├── public/                       # Public files
│   └── index.html                # Main HTML file
├── terraform/                    # AWS deployment configuration
├── docs/                         # Documentation
├── scripts/                      # Build and deployment scripts
├── tests/                        # Test files
│   ├── unit/                     # Unit tests
│   └── integration/              # Integration tests
├── config/                       # Configuration files
├── Dockerfile                    # Docker configuration
├── docker-compose.yml            # Docker Compose setup
├── package.json                  # Node.js dependencies
├── .eslintrc.json               # ESLint configuration
├── .prettierrc                  # Prettier configuration
└── README.md                    # This file
```

## 🚀 Quick Start

### Prerequisites

- Modern web browser with ES6 module support
- Python 3 (for local development server)
- Node.js (for development tools)

### Local Development

```bash
# Clone the repository
git clone <your-repo-url>
cd Javascript2DGameTutorial

# Install development dependencies (optional)
npm install

# Start local development server
npm start
# or
python3 -m http.server 8000

# Open browser to http://localhost:8000/public/
```

### Docker Development

```bash
# Build and run with Docker
npm run docker:compose

# Or manually
docker build -t javascript-2d-game .
docker run -p 8080:80 javascript-2d-game
```

## 🎯 Game Controls

| Key | Action |
|-----|--------|
| **Arrow Keys** | Move player ship |
| **1** | Shoot projectile |
| **2** | Use small laser |
| **3** | Use big laser |
| **R** | Restart game |
| **A** | Toggle AI agent |
| **D** | Cycle AI difficulty |

## 🤖 AI Agent

The game features an intelligent AI agent that can:

- **Analyze game state** in real-time
- **Make strategic decisions** about movement and shooting
- **Adapt to different difficulty levels**
- **Learn from gameplay patterns**

### AI Difficulty Levels

- **Easy**: Slower decision making, basic strategies
- **Medium**: Balanced performance, moderate complexity
- **Hard**: Fast reactions, advanced tactics

### AI Features

- **Threat assessment** and risk evaluation
- **Optimal positioning** based on enemy locations
- **Collision avoidance** and dodging
- **Resource management** (energy conservation)
- **Target prioritization** (enemies vs bosses)

## 🏗️ Architecture

### Modular Design

The game follows modern JavaScript practices with:

- **ES6 Modules** for clean imports/exports
- **Class-based architecture** for game objects
- **Separation of concerns** between game logic and rendering
- **Event-driven architecture** for user input
- **Object pooling** for performance optimization

### Key Components

1. **Game Engine** (`Game.js`)
   - Main game loop and state management
   - Collision detection system
   - Resource management

2. **Game Objects** (`classes/`)
   - Player, enemies, projectiles, lasers
   - Each class handles its own behavior and rendering

3. **AI System** (`ai-agent.js`)
   - State observation and analysis
   - Decision-making algorithms
   - Action execution

4. **Rendering System**
   - Canvas-based rendering
   - Sprite animation system
   - UI overlay management

## 🔧 Development

### Code Quality

```bash
# Lint code
npm run lint

# Format code
npm run format

# Run tests (when implemented)
npm test
```

### Adding New Features

1. **New Game Objects**: Create new classes in `src/js/classes/`
2. **New AI Behaviors**: Extend the AI agent in `src/js/ai-agent.js`
3. **New Assets**: Add to `src/assets/` and update references
4. **New Styles**: Modify `src/css/game.css`

### Testing

The project includes a test structure for:
- **Unit tests** for individual classes
- **Integration tests** for game systems
- **AI behavior tests** for agent functionality

## 🚀 Deployment

### AWS EKS Deployment

The project includes comprehensive Terraform configuration for AWS deployment:

```bash
cd terraform
./deploy.sh init
./deploy.sh deploy dev
```

See `terraform/README.md` for detailed deployment instructions.

### Docker Deployment

```bash
# Build and push to registry
docker build -t your-registry/javascript-2d-game .
docker push your-registry/javascript-2d-game

# Deploy to Kubernetes
kubectl apply -f k8s/
```

## 📊 Performance

### Optimizations

- **Object pooling** for projectiles and enemies
- **Efficient collision detection** algorithms
- **Canvas optimization** with proper clearing and redrawing
- **Memory management** with proper cleanup
- **Frame rate optimization** with delta time calculations

### Browser Compatibility

- **Modern browsers** with ES6 module support
- **Canvas API** for rendering
- **RequestAnimationFrame** for smooth animations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code structure and naming conventions
- Add JSDoc comments for new functions and classes
- Ensure code passes linting (`npm run lint`)
- Test your changes thoroughly
- Update documentation as needed

## 📚 Resources

- [Canvas API Documentation](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)
- [ES6 Modules Guide](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules)
- [Game Development Patterns](https://gameprogrammingpatterns.com/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by classic Space Invaders
- Built with modern JavaScript best practices
- AI agent based on game AI research
- Deployment infrastructure following AWS AppMod Blueprints patterns 