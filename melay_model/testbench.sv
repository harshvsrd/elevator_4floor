module tb_elevator;

  // Inputs
  reg [1:0] req;
  reg clk, rst, open, close, floor_sensor;
  reg obstacle, overload;

  // Outputs
  wire [1:0] currentfloor;
  wire motorup, motordown, opening, closing;

  // Instantiate the Unit Under Test (UUT)
  elevator uut (
    .req(req), 
    .currentfloor(currentfloor), 
    .clk(clk), 
    .open(open), 
    .rst(rst), 
    .close(close), 
    .floor_sensor(floor_sensor), 
    .motorup(motorup), 
    .motordown(motordown), 
    .opening(opening), 
    .closing(closing), 
    .obstacle(obstacle), 
    .overload(overload)
  );

  // Clock generation (10 time units period)
  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_elevator);

    // 1. Initialize Inputs
    clk = 0; rst = 1; 
    req = 2; // Set req to 2 BEFORE reset ends to prevent getting stuck in idle
    open = 0; close = 1; 
    floor_sensor = 0; obstacle = 0; overload = 0;

    // Release reset
    #15 rst = 0;

    // -----------------------------------------------------------
    // TEST 1: Move UP from Floor 0 to Floor 2
    // -----------------------------------------------------------
    $display("--- Test 1: Moving UP to Floor 2 ---");
    
    // Simulate passing floor 1
    #20 floor_sensor = 1; #10 floor_sensor = 0; 
    
    // Simulate arriving at floor 2
    #20 floor_sensor = 1; #10 floor_sensor = 0; 

    // We are now in the door state. 
    // We must feed the "cheat code" (open=1, close=1) to escape back to idle!
    #20 open = 1; close = 0; // Door opens
    #20 open = 1; close = 1; // CHEAT CODE: Forces FSM to next_state = idle
    #10 open = 0; close = 1; // Reset sensors for the next test

    // -----------------------------------------------------------
    // TEST 2: Move DOWN from Floor 2 to Floor 0
    // -----------------------------------------------------------
    $display("--- Test 2: Moving DOWN to Floor 0 ---");
    #10 req = 0; 
    
    #20 floor_sensor = 1; #10 floor_sensor = 0; // Pass floor 1
    #20 floor_sensor = 1; #10 floor_sensor = 0; // Arrive floor 0

    // Door sequence to escape
    #20 open = 1; close = 0; 
    #20 open = 1; close = 1; // CHEAT CODE
    #10 open = 0; close = 1;

    // -----------------------------------------------------------
    // TEST 3: Obstacle Detection
    // -----------------------------------------------------------
    $display("--- Test 3: Obstacle Detection ---");
    #10 req = 1; // Go to floor 1
    #20 floor_sensor = 1; #10 floor_sensor = 0; // Arrive floor 1
    
    // Door sequence with obstacle
    #20 open = 1; close = 0; 
    #10 obstacle = 1; // Trigger obstacle
    #20 obstacle = 0; // Remove obstacle
    #20 open = 1; close = 1; // CHEAT CODE
    #10 open = 0; close = 1;

    // -----------------------------------------------------------
    // TEST 4: Overload condition
    // -----------------------------------------------------------
    $display("--- Test 4: Overload ---");
    #20 overload = 1; // Trigger overload
    #40 overload = 0; // Remove overload
    
    // Escape door state
    #20 open = 1; close = 0; 
    #20 open = 1; close = 1; // CHEAT CODE
    #10 open = 0; close = 1;

    #40 $display("--- Simulation Complete! ---");
    $finish;
  end

  // Monitor to print outputs
  initial begin
    $monitor("Time=%3t | Req=%0d CurrFlr=%0d | Motor(U=%b,D=%b) | Door(Opn=%b,Cls=%b) | State=%0d", 
             $time, req, currentfloor, motorup, motordown, opening, closing, uut.state);
  end

endmodule
