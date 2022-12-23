`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2021 07:33:42 PM
// Design Name: 
// Module Name: floatToStr
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


module intToStr(
    input signed [26:0]  float,
    output       [7:0]   signbuffer,
    output       [31:0]  outputbuffer,
    output reg           validout
    );
    
    reg signed  [26:0]  f;
    reg signed  [3:0]   a1,a2,a3,a4;
    wire        [7:0]  o1,o2,o3,o4;
    wire                negative;
    
    initial validout = 1;
    assign negative         = float[26];
    assign signbuffer       = (negative)? 8'h2D: 8'h2B;
    assign outputbuffer  = {o1,o2,o3,o4};
    
    intToChar i2c1(a1, o1);
    intToChar i2c2(a2, o2);
    intToChar i2c3(a3, o3);
    intToChar i2c4(a4, o4);
    
    always @(float) begin
        f = float;
        if(negative) f = -float;
        
        if(f>9999) validout = 0;
        else validout = 1;
        
        a1 = f/1000; f = f-a1*1000;
        a2 = f/100; f = f-a2*100;
        a3 = f/10; 
        a4 = f%10;
    end
endmodule

module intToChar(input [3:0] f, output reg [7:0] c);
    always @(f)
        case(f)
            0: c = 8'h30;
            1: c = 8'h31;
            2: c = 8'h32;
            3: c = 8'h33;
            4: c = 8'h34;
            5: c = 8'h35;
            6: c = 8'h36;
            7: c = 8'h37;
            8: c = 8'h38;
            9: c = 8'h39;
        endcase
endmodule