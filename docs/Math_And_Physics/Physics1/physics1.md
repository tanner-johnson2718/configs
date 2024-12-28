# Physics 1

## Abstract

Abstract The goal of this document is to organize, abstract, and consolidate that which is learned 
typically in a first semester college level, calc based physics course. More formally, it is define
the basic quantities and relations of interest in Newtonian Mechanics. Electricty and magnitism are
considered out of scope, as is more technical formulations of Newtonian physics such as Langrangian
mechanics. We will also discuss and generalize the application of these basic quantities and 
relations to simple systems. Focus will be on presenting the material from a first principals point 
of view and finding the essential take away of this subject.

## Position on Motion

The most unit we will consider in this document is that of the a point particle. This point particle
exists at a specific point in space given by a 3 dimensional vector over the real numbers. We will 
usually denote this as \(x\). Moreover, a particles state is also described by a time, \(t\). Thus it
occupies a point and a time. This is a single real number. Thus we can usually consider a function 
\(x(t)\) that takes a single real value and outputs a 3 dimensional spacial vector describing its 
position. The geometry of this 3+1 space is flat. In that the coordinates are not coupled in anyway 
and simply lie orthognal to one another.

Now, we describe motion as simply derivative with respect to time. So velocity \(v=\frac{dx}{dt}\) is\
the first derivative of position with respect to time. Acceleration \(a=\frac{d^{2}x}{dt^{2}}\). We 
will not further discuss this. Finally, a point particle also has an associated quantity mass, \(m>0\).
It is usually taken to be constant with time, but when disucssing collection of point particles we can
take about mass as a function of time. The mass is a measure of how “hard” it is to move the particle
and how much it resists acceleration. This will be formalized with Newton's laws, but as an initial
defintion mass is a scalar quantity associated with a point particle that gives its proprotionality 
constant to its resistance to motion.

So with this view of the universe, our world is very simply. Everything is composed of infimetisial
point particles. They are uniquely described by a 3+1 dimensional space-time, an operator \((\frac{d}
{dt})\) which gives its motion through the space, and a scalar quantity describing how much this point
particle doesn't like to move. From this we can describe a wide varity of physical phenonemon and with
additional laws, can define the ground work for all of classical physics.

## Newton's Laws

Newtwon's Laws are three laws which describe how we can set up equations that model how our universe 
we laid out in the previous section will evolve with time and what state will evolve through and too.
Before stating these law's we must introduce an additional construct in this universe. That is of a 
force. A force intuitivly is just a push or pull. It is fomally a 3 dimentional vector quantity that 
lies in our 3+1 space and acts on a point particle. It can vary with time and is fomally defined in 
the second. So, these law's are

1. The velocity of particle will not change unless acted upon by a force
2. A force induces an acceleration, inversly proportional to mass: F=ma
3. All forces have an equal and opposite reactionary force

It should be noted here that our chose of coordinates is free as long as are coordinate frames i,e. 
where we measure postion, velocity, and acceleration from are not exelerating relative to one another.
In other words if you are moving with constant velocity relative to some other observer you will 
observe the same forces and thus dynamics of whatever system you are studying. So a force is a push 
or a pull on a point particle, it is a vector, and we add the detail that it follows the laws of 
super posistion. That is if more than one force acts on a particle, the resulting dynamics are as if 
a single net force equal to the sum all forces is acting on the point particle \(F_{net}=\sum F_{i}\).
Now these laws lay out a simple universe. Our point particles in this universe do not change velocity 
unless there is a non zero force acting on it. A net force governs a particles acceleration. And for 
every force that exists there is an equal and opposite force that must also exist (usually on another 
body). Thus we have a recipe for constructing differential equations in our univers. First determine 
the forces acting on a system then simply solve the resulting differential equation \(F=ma\). Easier
said than done.

* Free falling
* Projectile motion
* Friction

## Energy and Work

* Total energy \(E=K+U+E_{leak}\)
* \(K=.5mv^{2}\)
* \(W=-\triangle U\)
* \(W=\intop F(x)dx\) in 1D and \(W=\intop F(x)\cdot ds \) in 3D
* \(F= -\frac{dU}{dx} \) in 1D and \(F=-\nabla U\)
* Could use some visuals here
* Energy is accounting tool that allows us to look over the details about what happens at two points 
  and only focus on the in and out, starting and final.
* Connection betwen work, force and potential
* How would anyone come up with the idea for energy?
* What about kinetic energy
* Well once you have \(E\) and \(KE\), \(U\) is no that much of a stretch
* Neither is the defintin of W as delta U, but how does that connect to defintion of force over a 
  displacement? Well no delta U unless there is a displacement
* Fundamental idea is that this quantity is conserved
* Springs and Pendulum

## Momentum and Impulse

* \(p=mv\)
* \(J=\triangle p\)
* \(F=\frac{dp}{dt}\)
* \(J=\int F(t)dt\)
* \(Collisions\)
* \(Conserved\)
* \(Rockets\)

## Angular Position and Motion

* Can replace \(x,v,a\) with \(\theta,w,\alpha\) 
* \(x\sim s=\theta r\) arc length. \(v_{t}=wr\) velocity always tangetial to path by defintion.
* uniform cirular motion
* Non unirform
* Acceleration has two components
* Acceleration to maintain uniform cicular motion points inward radially: \(a_{r}=w^{2}r=\frac{v^{2}}
  {r} \)
∗ Show this starting from paramteric equation of a circle
* Acceleration to increase angular velocity is tagential to path: \(a_{t}=\alpha r\)
• Period \(T=\frac{2\pi}{w}\)

## Torque, Newton's Laws in Angular Form, and Rigid Bodies

* \(F=ma\) ... \(Fr=mr^{2}\alpha\)  ... \(\tau=I\alpha\) 
* motiviates this \(K=.5mv^{2}=.5mw^{2}r^{2}=.5Iw^{2}\) where \(I=mr^{2}\)
* intuitive defintion of torqueq also motivates \(\tau=rF_{perp}\)
* \(I=\int r^{2}dm\)
* \(W=\int\tau d\theta\) 
* Parallel Axis Thereom. Prove it.
* Calculate moment of inertia for some bodies
* Thin uniform rod about its midpoint: \(I=\int r^{2}dm\) 
* \(dm=\frac{dx}{L}M\) and \(r(x)=x\).
* \(I=\frac{2M}{L}\intop_{0}^{L/2}x^{2}dx=\frac{2M}{3L}(\frac{L}{2})^{3}=\frac{ML^{2}}{12}\)
* \(\tau=r\times F\)
* \(l=r\times p\)
* \(L=Iw\)
* \(\tau=\frac{dl}{dt}\)
* Angular momentum conserved
* Rolling without slippage
* Rolling with slippage
* The yo-yo
