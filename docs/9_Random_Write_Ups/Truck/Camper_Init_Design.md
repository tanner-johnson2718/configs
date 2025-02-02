# Camper Init Design

Lets start with the mininum requirements:

* Bed space
* Heater - Will mount this underneath the truck on passenger side 
* Water System (Externally accessible)
* 12v Fridge / Freezer
* Desk
* Kitchen Area
* Propane (Externally accessible)
* Can fully stand up in most of the camper

## Floor Plan

The initial floor plan is something like the following:

![](./floor.svg)

The key Parameters are the following, we list here as these might change and these will
be the first values we port into CAD.

| Parameter | Value | Note |
| --- | --- | --- |
| Width (Inner) | 76" | - |
| Floor Length (Inner) | 75" | May need to shrink this |
| Bed Length | 76" | Equal to "Width (Inner)" |
| Bed Width | 38" | Adjustable bet set to twin size |
| Floor Width | 48" | - |
| Wing Width | 14" | - |
| Overhead Storage Length | 24" | - |
| Desk Depth | 24" | - |

* The 48" floor is the space between the wheel wells
* The rectangles opposite  the floor create the "wings" of the camper and will rest on the rails
* The bed rests on the rails creating a large storage space underneath the bed.
    * Fridge
    * Maybe shoes
    * Maybe battery and electrical distribution?
    * Maybe just open Storage
* Can put the water system and propane in the kitchen/desk area "above the wing"
  under the main table / desk
    * Add a hatch on the outside to access water and propane.
* Kitchen/Desk area
    * Sink and cutting board under a "hard cover" that folds down and gives me a desk 
* Overhead storage
    * Half Hanger / Clothes
    * Other half cubbies

## Rear Profile

The floor plan gives us a good overview but lets look at the rear profile, this will
define our door / entrance and our roof profile:
   
![](./back.svg)
  
Again the key parameters here are:
  
| Parameter | Value | Note |
| --- | --- | --- |
| Center Height | 80" | <ul><li>This is the single most important height measurement</li><li>Needs to be larger than 72" so as to create a "head pocket".</li></ul> |
| Wall Height | 64" | <ul><li>This measurement defines the slope of the roof.</li><li>Made this roughly eye level.</li><li>I think a few extra inches here is gonna go a long way.</li></ul> |
| Rail Height | 20.5" | - |
| Truck Bed Height | 31" | - |
| Clearance | 108" | Sum of Rail Height and Truck Bed Height |
  
* A key concept here is the notion of the **head pocket**, which is the volume of the interior of the camper where the ceiling is taller than 72".
* The next most important concept is the **roof slope** whose definition is self evident.
    * 4/12 is the mininum for metal roofing and 4/12 to 9/12 is the standard
    * Right now have a slope of 5/12 but can see wanting to increase this for asthectics and water shedding.
* Finally **clearance** is the last key value to consider for the rear profile
    * The camper is already gonna be tall.
    * Willing to add ~6" here if it greatly improves the looks or feel of the camper.
  
## Side Profile
    
The side profile is almost defined by the floor plan and the rear profile but,
  
![](./side.svg)
   
| Parameter | Value | Note |
| --- | --- | --- |
| Rail to Cab | 24" | - |
| Nose Height | 9.5" | Defined to give 5/12 slope from wall height to nose. |
  
* The side profile is hard to project to 2d because of the slope of the roof.
* Showing just the wall height and ignoring the center height.
* More appropriate to specify this in CAD.
  

