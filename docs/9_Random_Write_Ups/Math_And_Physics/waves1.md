# Waves 1

## Basic Waves


Consider taught string that is locked in place on one side and you are holding the other end. You jerk
it up and back to its orginal position. This produces a pulse. Your jerking the string up raises the 
next sction of string which raises the next section and so on. While you jerking it back down produces
the same affect momentarly delayed from the moving up. This creates a moving pulse that traversese 
the length of the string. This is a transverse because the direction of oscilation is perpendicular 
to the direction of travel. Like wise, consider a long cylinder of air with a piston on one end. As 
you drive the piston you create pulses of high and low pressure just as in the previous example. This
is a longitudinal wave because the direction of travel is parallel to the direction of the oscilation.
Both are said to be traveling because the wave form moves through the medium. The mathematics of a 
traveling wave are given below.

* Displacement) \(y(x,t)=h(kx\pm wt)\)
* Wave form) \(h(s)\). So the wave form is just how you drive the wave at \(x=0\).
* Speed of wave) \(v=\pm\frac{w}{k}\). Consider some point of constant displacement on the wave. 
  Now this implies \(kx\pm wt\) is constant. Taking a differential gives \(kdx\pm wdt=0\). Solving 
  for \(dx/dt\) gives the speed \(v\).

| Dimension | Angular Frequency | Units | Period / Wave Length |
| --- | --- |--- | ---|
| Time	    | \(w\)             | \([s^{-1}]\) | \(T=\frac{2\pi}{w} \) |
| Space	    | \(k\) 	        | \([m^{-1}]\) | \(\lambda=\frac{2\pi}{k}\) |

* The temporal frequency is determined by the force that is driving the wave, while the spatial 
  frequency is determined by the medium
* Using a very hand wavy derivation one can show the speed at which a wave propegates through a 
  string with linear density \(\mu\)  is given by \(v=\sqrt{\frac{\tau}{\mu}}\), where \(\tau\)  is 
  the tension in the wire. Thus using \(v=(1/k)w\) we can see that the spatial frequency is set by the
  medium since the speed is set by the medium.

**Confusion:**

* Why is it \(kx-wt\), still confused on that, but logic of following a point on the wave is the same 
  as saying kx\pm wt is constant makes sense. Looking at a differential makes sense. And the resulting 
  velocity being the temporal frequency divided by the spatial frequency makes sense. So if you run 
  that logic backwards one would arrive at \(kx-wt\) for the argument for the waveform. 
* If you drive wave with a non sine wave wave form, what do the temporal and spatial frequencies mean?
* How to determine the speed at which a wave goes through a medium without using the stupid derivation used in the book? i.e. find a better derivation
* What the hell is the spatial frequency intuitively. Radians per per meters, what does that mean.

**Code**

• wave.py just allows you to play with wave form, frequency, etc.

## Energy

You drive the LHS of the string with SHM. You could imagine that as you pull up from \(y=0\) this 
would not only stretch the string, maximally, but would also be the point where the string is moving 
the most. Moreover, at exactly \(y=y_{m}\) you could imagine that you are no longer stretching the 
string and at exactly that point there is no kinetic energy i.e. a single particle at the peak of its
SHM would be motionless. This reasoning about the kinetic energy follows from the same reasoning while
analyzing SHM. You could then intuitvly reason about the stretching by saying that well if the 
string's not moving its not being stretched, so the Energy associated with its motion must track with
the energy placed into the elastic potential energy of the string i.e. its stretching. Formally, 
consider a small string element of mass \(dm\) over a section \(dx\). Now consider the differential 
slice of the KE associated with its transverse (up and down) motion. Remember we are driving the wave
with SHM so it is a sine wave.

$$
dK=.5dm(\frac{\partial y}{\partial t})^{2}=.5(\mu dx)y_{m}^{2}w^{2}\cos^{2}(kx-wt)
$$

Now as you might have guessed, divide both sides by a small time differential to get a rate at which 
kinetic energy is transfered.

$$
\frac{dK}{dt}=.5\mu vy_{m}^{2}w^{2}\cos^{2}(kx-wt)
$$

Taking the average yields one half of the above because the average over the square cosine is one 
half. However we wish to analzye the total energy transfer which would include the elastic potential 
energy. But since we are driving this wave with SHM, we know that the average potential energy equals 
that of the kinetic as over time, kinetic and potential average to exactly half that of the total 
energy in SHM. Thus the rate at which total energy is transferred and the thus the average power is:

$$
P_{avg}=.5\mu vy_{m}^{2}w^{2}
$$

**Questions:**

* Could you calculate the elastic potential energy?
* This would give how much it is being stretched, right?

Well let us see if we can do that. First consider a section \(dx\). The length of the rope over this 
section is given by \(dl^{2}=dx^{2}+dy^{2}\). Now there is some tension T in the rope producing this 
stretch. Now potential is given by

$$
dU=.5k(dl-dx)^{2}
$$

We can ignore the cross term of the square and write

$$
dU=.5kdy^{2}
$$

**Code:**

* elastic.py simulates a rope as a series of point masses connected via springs. Can set init speed 
  and velocity of masses. Results show that \(F_{y}=-kdy\) and \(U=.5kdy^{2}\) are the correct forms 
  of force and potential and they lead to conservation of energy. 

## Deriving the 1D Wave Equation

First just accept that \(v^{2}=\frac{T}{\mu}\) where \(T\) is the tension in the string and \(\mu\) 
is the linear density. Moving on, consider a small slice of string \(dx\) with mass \(dm=\mu dx\), at
the point \(x\). Now there is some constant tension \(T\) in this string that acts tangent to the 
string at all times. Now consider this tension at the point \(x\) and at the point \(x+dx\). As the 
wave passes through the point x, it increases or decreases the slope of the tangent line at that 
point, causing a slight difference in the tension. Thus the acceleration upward or downward that our 
slice feels is just the net difference of the tension at \(x\) with the tension at \(x+dx\). Since the
tension is tangant to the rope, the net force is just the difference in the slope of the tangent line
between \(x\) and \(x+dx\) (scaled of course for the magnitude of the tension). Using Newtons law we 
can get a differential equation:

$$
F=T\frac{dy}{dx}(x+dx)-T\frac{dy}{dx}(x)=\mu dx\frac{d^{2}y}{dt^{2}}
$$

$$
\frac{T}{\mu}\frac{\frac{dy}{dx}(x+dx)-\frac{dy}{dx}(x)}{dx}=\frac{d^{2}y}{dt^{2}}
$$

We can clearly see that as we take limit of the length of our differential going to zero, we just get 
the second space derivative on the left. So,

$$
\frac{d^{2}y}{dt^{2}}=v^{2}\frac{d^{2}y}{dx^{2}}
$$

**Side Note**, this physical intuition gives us an interesting way to look at the second derivative 
operator. That is the second derivative tells us how much a point differs from the average of its two
neighbors. So consider three points, \(x-dx\), \(x\), \(x+dx\). Now the second order differential 
approximation is as follows:

$$
\frac{d^{2}u}{dx^{2}}=\frac{u(x+dx)-2u(x)+u(x-dx)}{dx^{2}}
$$

Using our above reasoning we can right this as the differnce betwen the slopes of two tangant lines

$$
u(x+dx)-2u(x)+u(x-dx)=(u(x+dx)-u(x))-(u(x)-u(x-dx))
$$

Finally, using this intuition we can think of the second derivative operator as measuring how much a 
point differs from the average of its two neighbors. Inuitively, if the tangent lines are the same at
both ends (and thus the tension difference is 0), then the middle point lies on the line connecting 
them and thus the net acceleration is 0 (i.e. the acceleration is 0). However, if there is a 
difference in the tangent lines (tension), \(u(x+dx)-u(x)\) differs from \(u(x)-u(x-dx)\), thus there
is a net force on the at \(x\). As shown below this is equivalent to the point \(x\) differing from 
the average of the two points around. Which again is equivalent to it not lying on the line 
connecting the two points around it.

$$
\frac{u(x+dx)+u(x-dx)}{2}-u(x)=\frac{u(x+dx)+u(x-dx)-2u(x)}{2}
$$

So we get an interesting way of looking at the wave equation. It says that looking at some line 
segement, the acceleration that line segment feels is proportional to how far displaced that point is
from the line connecting the two points to its left and right.

## Solving the Wave Equation and Boundary Conditions

## Interference and Phasors

Suppose you have two waves on the same medium, then the overal wave is just the superposition of the 
two: \(y(x,t)=y_{1}(x,t)+y_{2}(x,t)\). Consider two waves of equal amplitude that differ by some phase
\(\phi\). Then the resulting wave is:

$$
y(x,t)=y_{m}(\sin(kx-wt)+\sin(kx-wt+\phi))
$$

$$
y(x,t)=2y_{m}\cos(.5\phi)\sin(kx-wt+.5\phi)
$$

Thus the resulting wave is simpy a sin wave whose amplitude depends on how in phase the two 
contributing waves are. But what if the two waves do not have the same amplitudes, but still have the
same temporal and spatial frequency and are possibly shifted in phase? That is where phasors come 
into play. Phasors seem a bit silly, just use Euler's formula)Thus the resulting wave is simpy a sin 
wave whose amplitude depends on how in phase the two contributing waves are. But what if the two waves 
do not have the same amplitudes, but still have the same temporal and spatial frequency and are 
possibly shifted in phase? That is where phasors come into play. Phasors seem a bit silly, just use 
Euler's formula)

$$
y_{1}(x,t)=y_{1m}\sin(kx-wt)=\frac{1}{2i}(e^{i\xi}-e^{-i\xi})
$$

$$
y_{2}(x,t)=y_{2m}\sin(kx-wt+\phi)=\frac{1}{2i}(e^{i\xi+i\phi}-e^{-i\xi-i\phi})
$$

$$
(y_{1}+y_{2})(x,t)=\frac{1}{2i}(e^{i\xi}(1+e^{i\phi})-e^{-i\xi}(1-e^{-i\phi}))
$$

Where \(\xi=kx-wt\). So let \(e^{i\alpha}=(1+e^{i\phi})\) and \(e^{-i\beta}=(1-e^{-i\phi})\)

$$
(y_{1}+y_{2})(x,t)=\frac{1}{2i}(e^{i\xi+i\alpha}-e^{-i\xi}(1-e^{-i\phi-i\beta}))
$$

Now multipy and divide by \(e^{(\beta-\alpha)i/2}\)

$$
(y_{1}+y_{2})(x,t)=\frac{e^{i(\alpha-\beta)/2}}{2i}(e^{i\xi+\alpha i/2+\beta i/2}-e^{-i\xi}(1-e^{-i\phi-\beta i/2-\alpha i/2}))
$$

$$
(y_{1}+y_{2})(x,t)=y_{m}'\sin(kx-wt+\gamma)
$$

Where \(y'_{m}=e^{i(\alpha-\beta)/2}\) and \(\gamma=\frac{\alpha+\beta}{2}\).

* Standing Waves
* Reasonance
