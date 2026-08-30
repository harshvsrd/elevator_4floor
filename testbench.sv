module tb_elevator;

  reg [3:0] req;
  reg clk, rst, open, close, floor_sensor, obstacle, overload;
  wire [1:0] currentfloor;
  wire motorup, motordown, opening, closing;

  elevator uut (
    .req(req), .currentfloor(currentfloor), .clk(clk), 
    .open(open), .rst(rst), .close(close), .floor_sensor(floor_sensor), 
    .motorup(motorup), .motordown(motordown), .opening(opening), 
    .closing(closing), .obstacle(obstacle), .overload(overload)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_elevator);

    clk = 0; rst = 1; req = 4'b0000;
    open = 0; close = 1; floor_sensor = 0; obstacle = 0; overload = 0;
    #15 rst = 0;

    // TEST 1: Multiple Requests (Sweep UP)
    #10 req = 4'b1010; 
    #10 req = 4'b0000; 
    #20 floor_sensor = 1; #10 floor_sensor = 0; 
    #20 open = 1; close = 0; 
    #20 open = 0; close = 1; 
    #20 floor_sensor = 1; #10 floor_sensor = 0;
    #20 floor_sensor = 1; #10 floor_sensor = 0;
    #20 open = 1; close = 0; 
    #20 open = 0; close = 1; 

    // TEST 2: Move DOWN
    #10 req = 4'b0001; 
    #10 req = 4'b0000;
    #20 floor_sensor = 1; #10 floor_sensor = 0; 
    #20 floor_sensor = 1; #10 floor_sensor = 0; 
    #20 floor_sensor = 1; #10 floor_sensor = 0; 
    #20 open = 1; close = 0; 
    #20 open = 0; close = 1; 

    // TEST 3: Obstacle Detection
    #10 req = 4'b0100; 
    #10 req = 4'b0000;
    #20 floor_sensor = 1; #10 floor_sensor = 0; 
    #20 floor_sensor = 1; #10 floor_sensor = 0; 
    #20 open = 1; close = 0; 
    #10 obstacle = 1;        
    #20 obstacle = 0;        
    #20 open = 0; close = 1; 

    // TEST 4: Overload
    #20 overload = 1; 
    #40 overload = 0; 
    #20 open = 1; close = 0; 
    #20 open = 0; close = 1; 

    #40 $finish;
  end

  initial begin
    $monitor("Time=%3t | Req=%b CurrFlr=%0d | Motor(U=%b,D=%b) | Door(Opn=%b,Cls=%b) | State=%0d | Mem=%b", 
             $time, req, currentfloor, motorup, motordown, opening, closing, uut.state, uut.pending_reqs);
  end

endmodule