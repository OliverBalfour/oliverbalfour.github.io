---
layout: post
title: "Better Observer Pattern in C++ using Unions"
categories: cpp
---

The Observer design pattern is a common way of decoupling code in large applications and passing event data between the various parts of applications.

Traditionally, the Observer design pattern is implemented using subclasses of a base `Subject` and `Observer` class for every possible type of data that needs to be sent between the two classes, or implemented to only be able to send the type of event, but no event specific data. Both of these common implementations fall apart very quickly; in the first approach, you end up with hundreds of lines of boilerplate that has to be manually changed if the interfaces with `Subject`s and `Observer`s change; and in the latter you can't even describe which key is being pressed in a keyboard handling system.

However, using C/C++'s `union`s we can remove the need for subclassing completely and use the same system to send different kinds of data across our entire application, no matter how diverse the uses of the Observer pattern are.

Unions are like structs, except only one member of a union can be populated at any time, as only enough space is reserved for the size of the largest member of the union. This means that if we send a enumerated event type and a union containing various event data structs between Subject and Observer, we can send any kind of data associated with the event. If we had a subject notifying upon mouse movement, we could add a mouse movement struct to the data union which contains the new x and y coordinates of the mouse. We could also use the same subject class for sending data about current bitcoin prices, if we added a struct representing that data to the union.

So, we create a union that stores one struct at a time, and that struct contains event specific data. Instead of having to subclass Subject and Observer classes for each type of data, we have our Subject emit an `Event` union that stores only the data for whatever event is being triggered. This comes with one small, but easily solvable, issue: knowing what type of data is being transmitted by the `Event` union. We could send an additional enum informing us of which struct (and hence event type) to expect, however a far more elegant solution is to copy the C multimedia library, SDL, in which we add an event type enumeration as the first member of the `Event` union and as the first member of each child struct (must always be the first member of the union and of all structs, otherwise different locations in memory are used.) This allows us to access, for example, `event.structName.type` as `event.type`, meaning we can essentially have two active members of the union at all times - an event type enumeration and the event data. This works because the same space in memory is used for `event.structName.type` as would be used for `event.type` if the `type` enumeration were the active member of the union, a neat little hack that saves us typing. This means we can just `switch` for the `event.type` and call it a day.

Here is an example of an event type enumeration, some event data structs, and the `Event` union.

```cpp
enum EventType {
	KEY_DOWN_EVENT,
	KEY_UP_EVENT,
	MOUSE_MOTION_EVENT,
	BITCOIN_PRICE_CHANGE_EVENT,
	RANDOM_OTHER_EVENT
};

// This struct handles KEYDOWN and KEYUP; no point creating two structs with the same signature
struct KeyEvent {
	EventType type;
	int keycode;
};
struct MouseMotionEvent {
	EventType type;
	int x, y;
};
struct BitcoinEvent {
	EventType type;
	double changeAmount, changePercent;
	unsigned int time; // time in milliseconds since last update
};
struct RandomEvent {
	EventType type;
	double pi;
	std::string name;
	RandomClass* thing;
};

union Event {
	EventType type;
	KeyEvent key;
	MouseMotionEvent mouse;
	BitcoinEvent btc;
	RandomEvent rnd;
};
```

So, to use this method, we create a single `Subject` class, which we create instances of, and a base `Observer` one, which we subclass. We only subclass the observer one to overwrite a virtual `onNotify` method, which is called whenever the subject is triggered with the event data. The `Subject` class contains methods to add and remove observers, and a method to notify all observers, sending an `Event`. The `Observer` class is very lightweight, with only a single virtual method taking the `Event` data. Below is a basic implementation of the `Subject` and `Observer` classes:

`observer.hpp`
```cpp
#ifndef OBSERVER_HPP
#define OBSERVER_HPP

#include <vector>
#include <algorithm>

#include "input.hpp"

class Observer {
	public:
		virtual void onNotify (const Event& input) = 0;
};

class Subject {
	public:
		void addObserver (Observer* obs);
		void removeObserver (Observer* obs);
		void notify (const Event& input);
	protected:
		std::vector<Observer*> observers;
};

#endif
```

`observer.cpp`
```cpp
#include "observer.hpp"

void Subject::addObserver (Observer* obs) {
	observers.push_back(obs);
}

void Subject::removeObserver (Observer* obs) {
	auto it = std::find(observers.begin(), observers.end(), obs);
	if (it != observers.end())
		observers.erase(it);
}

void Subject::notify (const Event& input) {
	for (int i = 0; i < observers.size(); i++) {
		observers[i]->onNotify(input);
	}
}
```

And an example of usage (very stripped down code):

```cpp
// Initialising subject and observer:
Subject kbdEvents;
// `Player` inherits from imaginary class `Entity` and our `Observer` class
// player.onNotify is called whenever inputEvents.notify is
Player player;
kbdEvents.addObserver(player);

// Notifying subject and hence observer(s):
void pollKeys () {
	Event input;
	// Type is keydown, code is 32 (space, I believe)
	// Obviously, don't hardcode values like below
	input.key = { KEY_DOWN_EVENT, 32 };
	kbdEvents.notify(input);
}
```

As you can see, this is much nicer to read and work with than other Subject/Observer implementations in C++. In this implementation, you simply need to add a struct to the `Event` union to support another format of event data. Note that you should not include large class instances in the event data structs, but pointers instead, as this will save a lot of memory.

Thanks for reading.
