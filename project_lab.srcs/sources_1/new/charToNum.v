`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2022 02:33:40 AM
// Design Name: 
// Module Name: charToNum
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


module charToNum(
    input [31:0] buffer,
    output [15:0] num
    );
    
    wire    [3:0]   a1,a2,a3,a4;
    wire    [7:0]   i1,i2,i3,i4;
    assign {i1,i2,i3,i4} = buffer;
    assign num = {a1,a2,a3,a4};
    charToNum1 c1(i1, a1);
    charToNum1 c2(i2, a2);
    charToNum1 c3(i3, a3);
    charToNum1 c4(i4, a4);
    
endmodule

module charToNum1(input wire [7:0] c, output reg [3:0] i);
    always @(c)
        case(c)
            8'h30: i=0;
            8'h31: i=1;
            8'h32: i=2;
            8'h33: i=3;
            8'h34: i=4;
            8'h35: i=5;
            8'h36: i=6;
            8'h37: i=7;
            8'h38: i=8;
            8'h39: i=9;
        endcase
endmodule
