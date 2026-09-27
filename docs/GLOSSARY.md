# Glossary — every technical word in this project, explained simply

Written for teammates, evaluators, and municipal staff. No prior AI knowledge assumed.
If you meet a word in this repo that is not here, add it.

---

## The AI and vision words

**Computer Vision (CV)**
Teaching a computer to understand pictures and video, the way a person does when they
glance at a road and think "that's a pothole".

**Model**
The trained "brain" of the system. You show it thousands of labelled examples, it
learns the pattern, and afterwards it can judge pictures it has never seen.

**Training**
The process of showing the model examples until it learns. Takes hours on a good
graphics card.

**YOLO ("You Only Look Once")**
A popular family of models that finds objects in an image *and* draws a box around each
one. The "only look once" part means it is fast enough to run on live video. We use it
for potholes, manholes and cracks.

**Bounding box**
The rectangle the model draws around a thing it found. Important for us because a box
tells you *where* the pothole is in the frame, which is what lets us work out where it
is in the real world. A model without boxes is useless to us.

**Object detection vs. classification**
- *Classification* answers "is there a pothole in this picture?" — yes or no.
- *Detection* answers "where exactly, and how many?"

We need detection. One of the public repos we reviewed only does classification, which
is why we rejected it.

**Segmentation**
Instead of a box, the model colours in every pixel: "this pixel is road, this pixel is
footpath, this pixel is sky." Slower than detection but far more precise. We need it to
answer questions about footpaths, which are shapes, not objects.

**Inference**
Actually *using* a trained model on new data. Training is learning; inference is doing.

**Edge / on-device inference**
Running the model on the phone itself instead of sending video to a server. Cheaper, more
private, works without signal — but the phone has far less power, so the model must be
shrunk first.

**Quantisation**
Shrinking a model by storing its numbers less precisely (e.g. 8-bit instead of 32-bit).
Makes it much faster and smaller, at a small cost in accuracy.

---

## The measurement words

**mAP (mean Average Precision)**
The standard score for a detection model, from 0 to 1. Higher is better. It balances
"did you find everything?" against "were you right when you spoke up?". Usually written
`mAP@50`, meaning a detection counts as correct if its box overlaps the true box by 50%.

**Precision**
Of all the things the model called a pothole, what fraction really were potholes?
Low precision = the model cries wolf.

**Recall**
Of all the real potholes out there, what fraction did the model actually find?
Low recall = the model misses things.

You can always trade one for the other. Reporting only one is a way of hiding the
other. We report both.

**False positive (FP)**
The model says "pothole" and there is no pothole. For us this is the expensive mistake:
it sends a repair crew to a road that is fine, and it destroys the department's trust.

**False negative (FN)**
A real pothole the model missed.

**Held-out / evaluation set**
Labelled examples we deliberately keep away from training, so we can honestly test the
model on things it has never seen. Testing a model on data it trained on is like marking
your own exam with the answer sheet open.

---

## The location words

**GPS**
The phone's location sensor. Accurate to roughly ±5 metres on a normal phone — good, but
not perfect, and that imperfection drives several of our design decisions.

**Geotagging**
Attaching a location to a piece of data. Every video frame we capture carries the GPS
reading from the moment it was taken.

**IMU / accelerometer**
The sensor that knows when the phone is shaken or tilted. When a car wheel drops into a
pothole, the phone jolts vertically. We use that jolt as independent evidence that the
pothole is real. A shadow on the road cannot shake the car.

**Ground projection**
Working out the real-world location of something we saw in a picture. If we know how high
the camera is mounted, what angle it points at, and where the bottom of the pothole's box
sits in the frame, we can estimate how far ahead the pothole is — then combine that with
GPS and the direction of travel to get its actual coordinates.

**Clustering**
Grouping nearby things together. If forty detections all land within a few metres of each
other, they are almost certainly the same pothole seen forty times.

**DBSCAN**
The specific clustering method we use. Its useful property is that you do not have to
tell it how many clusters to expect — you just tell it how close things must be to count
as the same thing. That distance is called **epsilon**.

**Epsilon (eps)**
The "how close is the same thing?" distance in DBSCAN. We use roughly 6–8 metres.
It has to be larger than our GPS error, or one pothole gets split into several tickets.

**OpenStreetMap (OSM)**
A free, open map of the world that anyone can use. We use it to know where roads and
junctions are, which lets us ask "should there be a zebra crossing here?"

**Road graph / way ID**
OSM stores roads as lines with unique IDs. Snapping our issues onto these lines means
every problem is attached to a *named road in a named ward*, not just floating
coordinates.

---

## The system words

**Deduplication**
Merging many observations of the same thing into one record. The single most important
function in this project.

**Ticket / work order**
The output of our system. One real-world problem, described, located, ranked by severity,
and assigned to a department.

**Lifecycle**
The stages a ticket moves through from being raised to being verified as fixed.
Ours has six: New → Verified → Assigned → In Progress → Resolved → Fix Verified.

**Negative guard**
A rule that *subtracts* confidence when something looks like a known false-positive
pattern — a wet patch reflecting the sky, a tar repair that resembles a pothole, a
shadow. Borrowed from KAVACH, which used 40 of them to reach a 0% false-positive rate.

**Severity**
How urgent a problem is. Made from estimated size, the jolt strength from the
accelerometer, how important the road is, and how many times we have seen it.

**SLA (Service Level Agreement)**
The promised time limit for fixing something, e.g. "critical potholes within 7 days".
The dashboard tracks whether tickets are being closed within it.

---

## The dataset words

**RDD2022**
A public research dataset: 47,420 photos of damaged roads from six countries, with over
55,000 damage areas already marked by humans. The India portion was photographed using
phones mounted on cars — exactly our setup.

**IDD (India Driving Dataset)**
A public dataset from IIIT Hyderabad: about 10,000 Indian road scenes with every pixel
labelled, covering 34 categories. Built specifically for messy, unstructured Indian
traffic, so it includes things European datasets omit — like the drivable dirt beside
the road where there is no proper footpath.

**Roboflow Universe**
A website hosting thousands of community-labelled datasets. Useful for filling gaps.

**Annotation / labelling**
A human drawing boxes around potholes to teach the model. Slow and expensive, which is
why using existing labelled datasets saves us months.

---

## The licence words

**Apache 2.0**
Our licence. Permissive — anyone can use our code, including commercially, as long as
they credit us.

**MIT**
Another permissive licence. Fine to reuse.

**AGPL-3.0**
A "copyleft" licence. If you build on AGPL code and run it as a service, you must
publish your source too. Ultralytics YOLO uses this. Fine for us because we publish
anyway, but it matters if anyone commercialises SETU later.

**No licence**
If a repository has no licence file, the law's default is **all rights reserved** —
nobody may reuse it. This is why we rejected one of the public pothole repos, despite
it having 49 stars.
