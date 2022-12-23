`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2021 07:27:04 PM
// Design Name: 
// Module Name: system
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

module system(output [1:0]led ,output wire RsTx, input wire RsRx,input clk, input btnC, output [6:0] seg, output dp, output [3:0] an);
    
    //////////////////////////////////
    // uart
    wire                baud;           // baudrate
    baudrate_gen baudrate(clk, baud);
    
    wire    [7:0]       data_out;       // 1 char from receive
    wire                received;       // = received 8 bits successfully
    reg                 last_rec;       // = check if received is new
    wire                new_input;
    assign new_input = ~last_rec & received;
    uart_rx receiver(baud, RsRx, received, data_out);
    
    reg     [7:0]       data_in;        // 1 char to transmit
    wire                sent;           // = sent 8 bits successfully
    reg                 wr_en;          // = enable transmitter
    uart_tx transmitter(baud, data_in, wr_en, sent, RsTx);
    
    //////////////////////////////////
    // push button
    wire                reset;
    singlePulser resetButton(reset, btnC, baud);
    
    //////////////////////////////////
    // r/w buffer
    reg     [87:0]      writebuffer;    // 11 chars
    reg     [31:0]      readbuffer;     // 4 chars
    
    //////////////////////////////////
    // casting i/o
    reg     [31:0]      inputbuffer;
    wire    [26:0]      inputval;
    strToInt inputCast(inputbuffer, inputval);
    
    wire    [87:0]      outputbuffer;
    wire    [26:0]      outputval;
    wire                validOutput;    // for invalid output (NaN)
    wire    [7:0]       signbuffer;
    wire    [31:0]      buffer;
    assign outputbuffer = {16'h0D0A,signbuffer,buffer,32'h203E3E20};
    
    intToStr outputCast(outputval, signbuffer, buffer, validOutput);
    
    //////////////////////////////////
    // calculation
    reg     [2:0]       op;             // 0+ 1- 2* 3/ 4s 5c
    reg                 enterkey;
    reg                 calculate;
    calculator cal(baud, reset, inputval, op, calculate, outputval);

    //////////////////////////////////
    // 7-segment Display
    wire [3:0]  num3,num2,num1,num0; // From left to right
    reg [15:0] num; 
    wire [15:0] inputnum, outputnum;
    assign {num3,num2,num1,num0}= num;
    charToNum inputNum(readbuffer, inputnum);
    charToNum outputNum(buffer, outputnum);
    
    wire negative;
    assign negative = outputval[26] ;
    
    reg led0 ;
    assign led = {led0} ;
    
    wire an0,an1,an2,an3;
    assign an={an3,an2,an1,an0};
    
    wire targetClk;
    wire [18:0] tclk;
    assign tclk[0]=clk;
    genvar c;
    generate for(c=0;c<18;c=c+1) begin
        clockDiv fDiv(tclk[c+1],tclk[c]);
    end endgenerate
    
    clockDiv fdivTarget(targetClk,tclk[18]);
    quadSevenSeg q7seg(seg,dp,an0,an1,an2,an3,num0,num1,num2,num3,targetClk);
    
    //////////////////////////////////
    // state
    reg     [2:0]       state;
    parameter STATE_OPERATOR        = 3'd0;
    parameter STATE_NUMBER    	    = 3'd1;
    parameter STATE_SENDMORE    	= 3'd2;
    parameter STATE_DELAY           = 3'd3;
    parameter STATE_ENTERKEY        = 3'd4;
    parameter STATE_CALCULATE       = 3'd5;
    
    reg     [3:0]       sendlen;        // length of sending sting
    reg     [7:0]       counter;        // for delay state
    
    reg operator;                       // 1 = need new operator , 0 = no more operator needs
    
    initial begin
        sendlen = 11; counter = 0; enterkey = 1; op = 5; operator = 1;
        readbuffer   = 32'h30303030;
        writebuffer     = {24'h0D0A2B,readbuffer,32'h203E3E20}; //(+0000 << )
        state = STATE_ENTERKEY;
    end

    always @(posedge baud) begin
        if(wr_en) wr_en=0;
        if(reset) begin
            sendlen = 0; counter = 0; enterkey = 1; op = 5; operator = 1;
            readbuffer   = 32'h30303030;
            writebuffer     = {24'h0D0A2B,readbuffer,32'h203E3E20};
            state = STATE_ENTERKEY;
        end
        case(state)
            STATE_OPERATOR:
                if(new_input) begin
                    case(data_out)
                        8'h63: op = 5; // c
                        8'h73: op = 4; // s
                        8'h2F: op = 3; // /
                        8'h2A: op = 2; // *
                        8'h2D: op = 1; // -
                        default: op = 0;
                    endcase
                    if(data_out == 13) begin enterkey = 1; inputbuffer = readbuffer; end
                    else if(data_out == 8'h08);
                    else begin
                        if(data_out >= 8'h30 && data_out <=8'h39) begin
                            readbuffer[31:8] = readbuffer[23:0];
                            readbuffer[7:0] = data_out;
                        end
                        sendlen = 1;
                        writebuffer[87:80] = data_out;
                    end
                    operator = 0;
                    state = STATE_ENTERKEY;
                end
            STATE_NUMBER:
                if(new_input) begin
                    case(data_out)
                        13: begin enterkey = 1; inputbuffer = readbuffer; end
                        default: 
                            if(data_out >= 8'h30 && data_out <=8'h39) begin // 0-9
                                readbuffer[31:8] = readbuffer[23:0];
                                readbuffer[7:0]  = data_out;
                                writebuffer[87:80]= data_out;
                                sendlen             = 1;
//                                num = inputnum;
                            end
                    endcase
                    state = STATE_ENTERKEY;
                end
            STATE_ENTERKEY: begin
                if(enterkey) begin
                    readbuffer      = 32'h30303030;
                    enterkey        = 0;
                    calculate       = 1;
                    state = STATE_CALCULATE;
                end
                else begin 
                    num = inputnum;
                    state = STATE_SENDMORE;
                end
            end
            STATE_CALCULATE: begin
                calculate = 0;
                if(counter < 32) counter = counter+1;
                else begin 
                    if(validOutput) begin
                        num = outputnum;
                        if(negative) begin 
                            led0 = 1'b1; 
                        end
                        else begin 
                            led0 = 1'b0; 
                        end
                        writebuffer = outputbuffer;
                    end
                    else begin
                        led0 = 1'b0; 
                        num = 16'b1111_1111_1111_1111;
                        writebuffer = 88'h0D0A204E614E20203E3E20;  //( NAN  >> )
                    end
                    sendlen = 11;
                    operator = 1; 
                    state = STATE_SENDMORE;
                    counter = 0;
                end
            end
            STATE_SENDMORE: begin
                if(sent & sendlen != 0) begin
                    wr_en       = 1;
                    data_in     = writebuffer[87:80];
                    writebuffer = writebuffer << 8;
                    sendlen     = sendlen - 1;
                    state       = STATE_DELAY;
                end
                else if(sendlen == 0) begin
                    if(operator)            state = STATE_OPERATOR;
                    else                    state = STATE_NUMBER;
                end
            end
            STATE_DELAY: begin
                if(counter < 11) counter = counter+1;
                else begin state = STATE_SENDMORE; counter = 0; end
            end
        endcase
        last_rec = received;
    end
endmodule