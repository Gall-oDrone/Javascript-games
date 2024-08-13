import { TILE_SIZE } from "../main.js";

export class GameObject {
    constructor({
        game, 
        sprite, 
        position, 
        scale
    }){
        this.game = game;
        this.sprite = sprite ?? {image:"",x:0,y:0,width:TILE_SIZE,height:TILE_SIZE,image:""};
        this.position = position ?? {x:0,y:0};
        this.scale = scale ?? 1;

        this.destinationPosition = {x: this.position.x, y: this.position.y};
        this.distanceToTravel = {x: 0, y: 0}
    }
    moveTowards(destinationPosition, speed){
        this.distanceToTravel.x = destinationPosition.x - this.position.x;
        this.distanceToTravel.y = destinationPosition.y - this.position.y;

        // let distance = Math.sqrt(this.distanceToTravel.x**2 + this.distanceToTravel.y**2);
        let distance = Math.hypot(this.distanceToTravel.x, this.distanceToTravel.y);

        if (distance <= speed) {
            // if close enoug, snap to position
            this.position.x = destinationPosition.x;
            this.position.y = destinationPosition.y;
        } else {
            // else take a step towards destination
            const stepX = this.distanceToTravel.x / distance;
            const stepY = this.distanceToTravel.y / distance;
            this.position.x += stepX * speed;
            this.position.y += stepY * speed;

            // remaining distance
            this.distanceToTravel.x = destinationPosition.x - this.position.x;
            this.distanceToTravel.y = destinationPosition.y - this.position.y;
            distance = Math.hypot(this.distanceToTravel.x, this.distanceToTravel.y);
        }
        return distance;
    }
    draw(ctx){
        ctx.fillStyle = 'blue';
        ctx.fillRect(
            this.position.x,
            this.position.y,
            TILE_SIZE,
            TILE_SIZE
        )
        ctx.drawImage(
            this.sprite.image, 
            this.sprite.x,
            this.sprite.y,
            this.sprite.width,
            this.sprite.height,
            this.position.x, 
            this.position.y,
            TILE_SIZE,
            TILE_SIZE
        )
    }
}