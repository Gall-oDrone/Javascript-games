# JavaScript 2D Game with AI Agent - Docker Setup

This repository contains a Space Invaders-style 2D game with an AI agent, containerized with Docker.

## 🐳 Docker Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
# Build and run the game
docker-compose up --build

# Access the game at: http://localhost:8080
```

### Option 2: Using Docker directly

```bash
# Build the Docker image
docker build -t javascript-2d-game .

# Run the container
docker run -d -p 8080:80 --name game-container javascript-2d-game

# Access the game at: http://localhost:8080
```

## 🎮 Game Controls

- **Arrow Keys**: Move player
- **1**: Shoot projectile
- **2**: Use small laser
- **3**: Use big laser
- **R**: Restart game
- **A**: Toggle AI Agent mode
- **D**: Change AI difficulty (Easy/Medium/Hard)

## 🏗️ Docker Configuration

### Dockerfile Features:
- **Lightweight**: Uses nginx:alpine base image
- **Optimized**: Includes gzip compression and caching
- **Secure**: Adds security headers
- **Performance**: Static asset caching for better load times

### Docker Compose Features:
- **Port Mapping**: Maps container port 80 to host port 8080
- **Health Checks**: Monitors container health
- **Auto-restart**: Container restarts unless manually stopped
- **Development Mode**: Uncomment volume mount for live development

## 🔧 Development Mode

For development with live reloading:

1. Uncomment the volume mount in `docker-compose.yml`:
```yaml
volumes:
  - .:/usr/share/nginx/html:ro
```

2. Run with:
```bash
docker-compose up --build
```

3. Changes to your files will be reflected immediately (no rebuild needed)

## 🚀 Production Deployment

### AWS EKS (as discussed earlier):
```bash
# Build and push to ECR
docker build -t your-registry/javascript-2d-game .
docker push your-registry/javascript-2d-game

# Deploy to EKS
kubectl apply -f k8s-deployment.yaml
```

### Simple Production:
```bash
# Build optimized image
docker build -t javascript-2d-game:prod .

# Run with production settings
docker run -d -p 80:80 --restart unless-stopped javascript-2d-game:prod
```

## 📁 File Structure

```
Javascript2DGameTutorial/
├── Dockerfile              # Docker configuration
├── docker-compose.yml      # Docker Compose setup
├── .dockerignore          # Docker build exclusions
├── index.html             # Main HTML file
├── style.css              # Game styles
├── script.js              # Main game logic
├── ai-agent.js            # AI agent implementation
└── README-Docker.md       # This file
```

## 🔍 Troubleshooting

### Container won't start:
```bash
# Check logs
docker-compose logs

# Check if port 8080 is available
lsof -i :8080
```

### Game not loading:
```bash
# Check container status
docker ps

# Access container shell
docker exec -it javascript-2d-game sh
```

### Performance issues:
- The nginx configuration includes gzip compression
- Static assets are cached for 1 year
- Consider using a CDN for production

## 🎯 Next Steps

1. **Test the AI Agent**: Press 'A' to activate AI mode
2. **Try different difficulties**: Press 'D' to cycle through Easy/Medium/Hard
3. **Deploy to cloud**: Use the provided Docker setup for AWS EKS deployment
4. **Add multiplayer**: Extend the AI agent for multiplayer scenarios 