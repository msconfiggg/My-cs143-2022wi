(*
 *  CS164 Fall 94
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *  Skeleton file
 *)

class Stack {

   top : String;
   next : Stack;
   trans : A2I <- new A2I;

   isEmpty() : Bool {
      false
   };

   init(t : String, n : Stack) : Stack {
      {
         top <- t;
         next <- n;
         self;
      }
   };

   top() : String {
      top
   };

   push(x : String) : Stack {
      (new Stack).init(x, self)
   };

   pop() : Stack {
      if self.isEmpty() then 
         self
      else 
         next
      fi
   };

   display() : Object {
      let i : IO <- (new IO) in
         if next.isEmpty() then
            i.out_string(top.concat("\n"))
         else {
            i.out_string(top.concat("\n"));
            next.display();
         } fi
   };



   execute() : Stack {
      let cmd : String <- top,
      arg1 : String,
      arg2 : String,
      newStack : Stack in
         if cmd = "+" then {
            newStack <- self.pop();
            arg1 <- newStack.top();
            newStack <- newStack.pop();
            arg2 <- newStack.top();
            newStack <- newStack.pop();
            newStack.push(trans.i2a(trans.a2i(arg1) + trans.a2i(arg2)));
         } else if cmd = "s" then {
            newStack <- self.pop();
            arg1 <- newStack.top();
            newStack <- newStack.pop();
            arg2 <- newStack.top();
            newStack <- newStack.pop();
            newStack <- newStack.push(arg1);
            newStack <- newStack.push(arg2);
         } else self fi fi
   };
 
};

class EmptyStack inherits Stack {

   isEmpty() : Bool {
      true
   };

};

class Main inherits IO {

   stack : Stack <- (new EmptyStack);
   command : String;

   main() : Object {
      let flag : Bool <- true in
         while flag loop {
            out_string(">");
            command <- in_string();
            if command = "+" then
               stack <- stack.push(command)
            else if command = "s" then
               stack <- stack.push(command)
            else if command = "d" then
               stack.display()
            else if command = "x" then
               flag <- false
            else if command = "e" then
               stack <- stack.execute()
            else stack <- stack.push(command)
            fi fi fi fi fi;
         }
         pool
   };

};
