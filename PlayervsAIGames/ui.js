class Ui {
    constructor(game){
        this.game = game;
        // display score
        this.scoreBoard1 = document.getElementById('scoreBoard1');
        this.scoreBoard2 = document.getElementById('scoreBoard2');
        this.scoreBoard3 = document.getElementById('scoreBoard3');
        this.scoreBoard4 = document.getElementById('scoreBoard4');
    }
    update(){
        this.scoreBoard1.innerText = this.game.player1.name + this.game.player1.score;
        this.scoreBoard2.innerText = this.game.player2.name + this.game.player2.score;
        this.scoreBoard3.innerText = this.game.player3.name + this.game.player3.score;
        this.scoreBoard4.innerText = this.game.player4.name + this.game.player4.score;
    }
}