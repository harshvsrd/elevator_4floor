// Code your design here
module elevator(
  input [1:0] req, 
  output reg [1:0] currentfloor,
  input clk,open,rst,close,floor_sensor,
  output reg motorup,motordown,opening,closing,
  input obstacle,overload);
  
  parameter idle=0;//idle
  parameter movingup=1;//movup
  parameter movingdown=2;
  parameter door=3;
  
 reg [1:0]state,next_state;
  
  always @(posedge clk)
    if(rst)
      begin
        state<=idle;
        currentfloor<=0;
      end
     else
       begin
         state<=next_state;
         if(floor_sensor)
           begin
             if(motorup&(req!=currentfloor))
               currentfloor<=currentfloor+1;
             else if(req==currentfloor)
               currentfloor<=currentfloor;
             else if(motordown&(req!=currentfloor))
               currentfloor<=currentfloor-1;
           end
       end
  
      always@(*)
        begin
          motorup=0;
          motordown=0;
          opening=0;
          closing=0;
          next_state=state;
          
            if(overload)
              begin
                next_state=door;
                if(!open)
                  opening=1;
              end
      else
          
          case(state)
            idle:begin
              if(req>currentfloor)
                begin
                  next_state=movingup;
                  motorup=1;
                end
              else if(req<currentfloor)
                begin
                  next_state=movingdown;
                  motordown=1;
                end
              else
                next_state=door;
            end
            
            movingup:if(req>currentfloor)
                begin
                  next_state=movingup;
                  motorup=1;
                end
              else
                next_state=door;
            
            movingdown:if(req<currentfloor)
                begin
                  next_state=movingdown;
                  motordown=1;
                end
              else
                next_state=door;
            
            door:begin
              opening=1;
              if(!open)
                next_state=door;
              else if(!close)
                begin
                  if(obstacle)
                    next_state=door;
                  else
                    begin
                      opening=0;
                      closing=1;
                      next_state=door;
                    end
                end
              else
                next_state=idle;
            end
              
              default:next_state=idle;
              
              endcase
            end
            endmodule