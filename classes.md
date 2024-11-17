## How to use this class system:

### 1. Define base class (basically a metatable for our cars)

```lua
---@alias Car gpm.std.Car                        <-- alias Car, so it is easier for us to reference it in params and etc.
---@class gpm.std.Car : gpm.std.Object           <-- do not forget to inherit from gpm.std.Object
---@field __class gpm.std.CarClass
local Car = std.class.base("Car")

---@protected               <-- do not forget to add protected so __init won't be shown
function Car:__init()
    self.speed = 0
    self.color = Color(255, 255, 255)
end
```

### 2. Define a class, which will be used to create a Car

```lua
---@class gpm.std.CarClass : gpm.std.Car      <-- do not forget to inherit from base
---@field __base gpm.std.Car
---@overload fun(): Car
local CarClass = std.class.create(Car)
std.Car = CarClass
```

### 3. Create a new car

```lua
local car = std.Car()
print(car.__name) -- Car
print(std.Car.__name == car.__name) -- true
print(car.speed) -- 0
```

### 4. Inherit from the Car class

```lua
---@alias Truck gpm.std.Truck
---@class gpm.std.Truck : gpm.std.Car
---@field __class gpm.std.TruckClass
---@field __parent gpm.std.CarClass               <-- now we need to define the parent, so LuaLS can know how to access our parent
local Truck = std.class.base("Truck", std.Car)


---@class gpm.std.TruckClass : gpm.std.Truck
---@field __base gpm.std.Truck
---@overload fun(): Truck
local TruckClass = std.class.create(Truck)
std.Truck = TruckClass
```

### 5. Optionally call inherited callback
```lua
std.class.inherited(TruckClass)
```
