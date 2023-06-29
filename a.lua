-- Meta class
Shape = {area = 0}
-- Base class method new
function Shape:new (o,side)
   o = o or {}
   self.__index = self
   setmetatable(o, self)
   side = side or 0
   self.area = side*side;
   return o
end
-- Base class method printArea
function Shape:printArea ()
   print("The area is ",self.area)
end
-- Creating an object
myshape = Shape:new(nil,10)
myshape:printArea()
Square = Shape:new()
-- Derived class method printArea
function Square:printArea ()
   print("The area of square is ",self.area)
end
function Square:printArea1 ()
   print("The area of square is ",self.area)
end
-- Creating an object
mysquare = Square:new(nil,10)
mysquare:printArea()