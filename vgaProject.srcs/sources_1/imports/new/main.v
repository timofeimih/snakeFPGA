`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.12.2018 17:07:27
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module main(
    input clk,
    input btnL,
    input btnU,
    input btnR,
    input btnD,
//    input sw0,
   
//    output led0,
    output wire Hsync,       // horizontal sync output
    output wire Vsync,       // vertical sync output
    output vgaRed,    // 4-bit VGA red output
    output vgaGreen,    // 4-bit VGA green output
    output vgaBlue     // 4-bit VGA blue output
);     

//    reg clk = 1'b0;
    
    
    reg start; 
    reg newMark;
    integer fieldx = 5 , fieldy = 5;
    //change to 9 bit later
    reg [8:0] map[0:5][0:5];
    
    integer i, g;
    
    integer snakeheadx, snakeheady;
//    integer snaketailx, snaketaily;
    
    //1 left, 2 top, 3 right, 4 bottom
    //reg [2:0] fromDirection;
    integer newsnaketailx, newsnaketaily;
    
    //1 left, 2 top, 3 right, 4 bottom
    reg left, top, right, bottom;
    
    reg [8:0] snakesize;
    reg [8:0] currentIndex;
    
    
    reg [8:0] tempIndex;
    integer tempx, tempy;
    
    // boolean check for directions
    reg checkGameOver = 1'b0, checkIsAMark = 1'b0;
    
    integer randomX = 0, randomY = 0;
    
    reg startGame;
    
    integer slow_clk = 0;
    
    wire enable;
    
    
    // generate a 25 MHz pixel strobe
    reg [15:0] cnt;
    reg pix_stb;    
    reg rst = 1'b0;
    wire animate;  // high when we're ready to animate at end of drawing

    wire [10:0] x;  // current pixel x position: 10-bit value: 0-1023
    wire [9:0] y;  // current pixel y position:  9-bit value: 0-511
    
    vga800x600 display (
        .i_clk(clk),
        .i_pix_stb(pix_stb),
        .i_rst(rst),
        .o_hs(Hsync), 
        .o_vs(Vsync), 
        .o_x(x), 
        .o_y(y),
        .o_animate(animate)
    );
    
    wire snakeBody, field, mark;
    integer squareSize = 30;
    
    
    assign snakeBody = ((x < fieldx*squareSize) &
               (y < fieldy*squareSize) & 
               (map[x / squareSize][y / squareSize] > 0) &
               (map[x / squareSize][y / squareSize] < 8'b11111111) &
               (x > (x / squareSize * squareSize)) &
               (y > (y / squareSize * squareSize)) &  
               (x < ((x+squareSize) / squareSize * squareSize)) &     
               (y < ((y+squareSize) / squareSize * squareSize))
                ) ? 1 : 0;
                        
    assign mark = ((x < fieldx*squareSize) & 
                (y < fieldy*squareSize) & 
                (map[x / squareSize][y / squareSize] == 8'b11111111) &
                (x > (x / squareSize * squareSize)) &
                (y > (y / squareSize * squareSize)) &  
                (x < ((x+squareSize) / squareSize * squareSize)) &     
                (y < ((y+squareSize) / squareSize * squareSize))) ? 1 : 0;
        
                        
    //assign sq_b = ((x > 200) && (y > 120) && (x < 360) && (y < 280)) ? 1 : 0;
    assign field = (x > 0 && y > 0 && (x <= fieldx*squareSize) && (y <= fieldy*squareSize)) ? 1 : 0;
    
    
    assign vgaGreen = snakeBody;
    //assign vgaBlue = field;
    assign vgaRed = mark;
    
        
//    assign led0 = sw0;
    
//    initial begin
//        bottom = 1;

//        #50;
        
//        $finish;
        
//    end
        
//    always #2 clk = ~clk;
//    assign enable = clk;
    
    
    assign enable = (slow_clk == 70); 
    
    initial begin
        for (i=0; i<=fieldx; i=i+1)
        begin
             for(g=0; g<=fieldy; g=g+1)
             begin
                 
                map[i][g] = 0;
              end      
        end
    end
    

    always @ (posedge clk)
    begin   
    
        {pix_stb, cnt} <= cnt + 16'h6666;  // divide by 2.5: (2^16)/2.5 = 0x6666

        
        randomY = randomY + 1;               
        if(randomY > fieldy - 1) randomY = 0;
           
         
        if(newMark == 1'b1) begin
            if(map[randomX][randomY] == 0) begin
                newMark = 1'b0;
                map[randomX][randomY] = 8'b11111111;
                $display("Mark new coordinates %d %d", randomX, randomY);
            end
        end
        
        if(btnL) begin
            if(right != 1) begin
                top = 0; bottom = 0; right = 0; left = 0;
                left = 1; 
            end
        end else if(btnU) begin
            if(bottom != 1) begin
                top = 0; bottom = 0; right = 0; left = 0;
                top = 1; 
            end
        end else if(btnR) begin
            if(left != 1) begin
                top = 0; bottom = 0; right = 0; left = 0;
                right = 1; 
            end
            
        end else if(btnD) begin
            if(top != 1) begin
                top = 0; bottom = 0; right = 0; left = 0;
                bottom = 1; 
            end
        end
     
//        $display("yes");
        //100
        if(animate && pix_stb) begin
            randomX = randomX + 1;      
            if(randomX > fieldx - 1) randomX = 0;
            
            if (slow_clk == 70) slow_clk = 0;
            else  slow_clk = slow_clk + 1;
            

            if(enable) begin
 
        
                if(startGame == 1'b1) begin
                
                    //2'b00 left, 2'b01 top, 2'b10 right, 2'b11 bottom
                    if(left) begin
                       $display("move left");
                       
                       // Check if need to add one more length or just move
                       checkIsAMark = map[snakeheadx-1][snakeheady] != 8'b11111111;
                       checkGameOver = (snakeheadx-1 < 0) || (map[snakeheadx-1][snakeheady]  > 0  && checkIsAMark);
                                             
                       snakeheadx = snakeheadx - 1;
                       snakeheady = snakeheady;
                    end else if(top) begin
                       $display("move top");   
                       // Check if need to add one more length or just move
                       checkIsAMark = map[snakeheadx][snakeheady - 1] != 8'b11111111;
                       checkGameOver = (snakeheady -1 < 0) || (map[snakeheadx][snakeheady - 1] > 0 && checkIsAMark);
                       
                       snakeheadx = snakeheadx;
                       snakeheady = snakeheady - 1;
                    end else if(right) begin
                       $display("move right");
                       
                       // Check if need to add one more length or just move
                       checkIsAMark = map[snakeheadx+1][snakeheady] != 8'b11111111;
                       checkGameOver = (snakeheadx + 1 == fieldx) || (map[snakeheadx+1][snakeheady] > 0 && checkIsAMark);
                       
                       snakeheadx = snakeheadx + 1;
                       snakeheady = snakeheady;
                    end else if(bottom) begin
                       $display("move down");
                       
                       // Check if need to add one more length or just move
                       checkIsAMark = map[snakeheadx][snakeheady + 1] != 8'b11111111;
                       checkGameOver = (snakeheady + 1 == fieldy) || (map[snakeheadx][snakeheady + 1] > 0 && checkIsAMark);
                       
                       snakeheadx = snakeheadx;
                       snakeheady = snakeheady + 1;
                       
                       
                    end
                    
                    
                    if(checkGameOver) begin
                        $display("game over snakeheady %d", snakeheady);
        
                        startGame = 1'b0;
                        top = 0;
                        bottom = 0;
                        left = 0;
                        right = 0;            

                        
                    end
                    
                    if(startGame == 1'b1) begin
                        if(left || top || right || bottom) begin
                            if(checkIsAMark) begin
                                $display("Not a mark");
                                
                                // доделать определение хвоста
    //                            if(map[snaketailx-1][snaketaily] == 2'b01) begin
    //                                newsnaketailx = snakeheadx-1;
    //                                newsnaketaily = snakeheady;
    //                            end else if(map[snakeheadx][snakeheady-1] == 2'b01) begin
    //                                newsnaketailx = snakeheadx;
    //                                newsnaketaily = snakeheady-1;
    //                            end else if(map[snakeheadx+1][snakeheady] == 2'b01) begin
    //                                newsnaketailx = snakeheadx+1;
    //                                newsnaketaily = snakeheady;
    //                            end else if(map[snakeheadx][snakeheady+1] == 2'b01) begin
    //                                newsnaketailx = snakeheadx;
    //                                newsnaketaily = snakeheady+1;
    //                            end
                                
    //                            map[snaketailx][snaketaily] = 2'b0;
    //                            snaketailx = newsnaketailx;
    //                            snaketaily = newsnaketaily;
                                
                                tempIndex = 8'b11111111;
                                tempx = 0;
                                tempy = 0;
                                for (i=0; i<=fieldx; i=i+1)
                                begin
                                     for(g=0; g<=fieldy; g=g+1)
                                     begin
                                        if(map[i][g] > 0 && map[i][g] < tempIndex) begin
                                            tempIndex = map[i][g];
                                            tempx = i;
                                            tempy = g;
                                        end
                                      end      
                                end
                                
                                map[tempx][tempy] = 0;
    //                            map[snakeheadx][snakeheady] = 0;
    //                            snaketailx = newsnaketailx;
    //                            snaketaily = newsnaketaily;
                                
                                currentIndex = currentIndex + 1;
                                map[snakeheadx][snakeheady] = currentIndex;
                                
                                
                            end else begin 
                                $display("mark");
    //                            $display("byte %b", map[snakeheadx][snakeheady + 1]);
                                
    //                            newMark = 1'b0;
    //                            while(newMark != 1'b1) begin
    //                                if(map[$urandom%20][$urandom%20] == 0) begin
    //                                    newMark = 1'b1;
                                        //map[{$random}%20][{$random}%20] = 1000;
    //                                end
    //                            end
                                currentIndex = currentIndex + 1;
                                map[snakeheadx][snakeheady] = currentIndex;
                                snakesize = snakesize + 1;
                                
                                
    //                            for (i=0; i<=fieldx; i=i+1)
    //                            begin
    //                                 for(g=0; g<=fieldy; g=g+1)
    //                                 begin
                                        
    //                                    if(map[i][g] == 0 && newMark == 1'b0) begin
    //                                        newMark = 1'b1;
    //                                        map[i][g] = 8'b1;
    //                                    end
    //                                 end      
    //                            end
                                newMark = 1'b1;
                            end
                
                         end
                    end
                end else begin
                    for (i=0; i<=fieldx; i=i+1)
                    begin
                         for(g=0; g<=fieldy; g=g+1)
                         begin
                             
                            map[i][g] = 0;
                          end      
                    end
                    
                    top = 0;
                    bottom = 0;
                    left = 0;
                    right = 0;
                    map[2][3] = 8'b11111111;
                    
                    map[1][1] = 8'd2;
                    map[1][0] = 8'd1;
                    snakeheadx = 1;
                    snakeheady = 1;
                    snakesize = 8'd2;
                    currentIndex = 8'd2;
                    
                    
    //                    snaketailx = 5;
    //                    snaketaily = 4;
                    
    
                    startGame = 1'b1;
                end
            end
        end
   end
    
endmodule

