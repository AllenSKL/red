Red/System [
	Title:   "Time! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %time.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

time: context [
	verbose: 0
	
	nano:  1E-9
	oneE9: 1E9
	h-factor: 3600.0 * oneE9
	m-factor: 60.0 * oneE9
	
	#define GET_HOURS(time)   (floor time / h-factor)
	#define GET_MINUTES(time) (floor time / oneE9 // 3600.0 / 60.0)
	#define GET_SECONDS(time) (time / oneE9 // 60.0)
	
	
	make-in: func [
		parent	[red-block!]
		high	[integer!]
		low		[integer!]
		return: [red-time!]
		/local
			cell [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/make-in"]]

		cell: ALLOC_TAIL(parent)
		cell/header: TYPE_TIME
		cell/data2: low
		cell/data3: high
		as red-time! cell
	]
	
	make-at: func [
		time	[float!]								;-- in nanoseconds
		cell	[red-value!]
		return: [red-time!]
		/local
			t [red-time!]
	][
		t: as red-time! cell
		t/header: TYPE_TIME
		t/time:   time
		t
	]
	
	box: func [
		time	[float!]								;-- in nanoseconds
		return: [red-time!]
	][
		make-at time stack/arguments
	]
	
	push: func [
		time	[float!]								;-- in nanoseconds
		return: [red-time!]
		/local
			t [red-time!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/push"]]
		
		make-at time stack/push*
	]
	
	;-- Actions --
	
	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-time!]
		/local
			int	 [red-integer!]
			fl	 [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				fl: as red-float! spec
				int: as red-integer! spec
				fl/value: oneE9 * integer/to-float int/value
				fl/header: TYPE_TIME
				as red-time! fl
			]
			TYPE_FLOAT [
				fl: as red-float! spec
				fl/header: TYPE_TIME
				fl/value: oneE9 * fl/value
				as red-time! fl
			]
			default [
				--NOT_IMPLEMENTED--
				as red-float! spec					;@@ just for making it compilable
			]
		]
	]

	
	form: func [
		t		[red-time!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/form"]]

		mold t buffer no no no arg part 0
	]
	
	mold: func [
		t		[red-time!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
			time   [float!]
			len	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/mold"]]
		
		time: t/time
		
		formed: integer/form-signed float/to-integer GET_HOURS(time)
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?

		string/append-char GET_BUFFER(buffer) as-integer #":"

		formed: integer/form-signed float/to-integer GET_MINUTES(time)
		len: length? formed								;@@ optimize by removing length?
		if len = 1 [
			string/append-char GET_BUFFER(buffer) as-integer #"0"
			len: 2
		]
		string/concatenate-literal buffer formed
		part: part - 1 - len
		
		string/append-char GET_BUFFER(buffer) as-integer #":"
		
		formed: float/form-float GET_SECONDS(time) float/FORM_FLOAT_64
		len: length? formed								;@@ optimize by removing length?
		if formed/2 = #"." [
			string/append-char GET_BUFFER(buffer) as-integer #"0"
			len: len + 1
		]
		string/concatenate-literal buffer formed
		part - 1 - len
	]
	
	eval-path: func [
		t		[red-time!]								;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			word   [red-word!]
			int	   [red-integer!]
			fl	   [red-float!]
			field  [integer!]
			sym	   [integer!]
			time   [float!]
			fval   [float!]
			error? [logic!]
	][
		time: t/time
		error?: no

		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				field: int/value
				if any [field <= 0 field > 3][error?: yes]
			]
			TYPE_WORD [
				word: as red-word! element
				sym: symbol/resolve word/symbol
				case [
					sym = words/hour   [field: 1]
					sym = words/minute [field: 2]
					sym = words/second [field: 3]
					true 			   [error?: yes]
				]
			]
			default [error?: yes]
		]
		if error? [fire [TO_ERROR(script invalid-path) stack/arguments element]]
		
		either value <> null [
			switch field [
				1 [
					if TYPE_OF(value) <> TYPE_INTEGER [fire [TO_ERROR(script invalid-arg) value]]
					int: as red-integer! value
					t/time: time - (GET_HOURS(time) - (integer/to-float int/value) * h-factor)
				]
				2 [
					if TYPE_OF(value) <> TYPE_INTEGER [fire [TO_ERROR(script invalid-arg) value]]
					int: as red-integer! value
					t/time: time - (GET_MINUTES(time) - (integer/to-float int/value) * m-factor)
				]
				3 [
					switch TYPE_OF(value) [
						TYPE_INTEGER [
							int: as red-integer! value
							fval: integer/to-float int/value
						]
						TYPE_FLOAT [
							fl: as red-float! value
							fval: fl/value
						]
						default [fire [TO_ERROR(script invalid-arg) value]]
					]
					t/time: time - (GET_SECONDS(time) - fval * oneE9)
				]
				default [assert false]
			]
			value
		][
			value: as red-value! switch field [
				1 [integer/push float/to-integer GET_HOURS(time)]
				2 [integer/push float/to-integer GET_MINUTES(time)]
				3 [float/push GET_SECONDS(time)]
				default [assert false]
			]
			stack/pop 1									;-- avoids moving stack up
			value
		]
	]
	
	divide: func [
		return: [red-value!]
		/local
			slot  [red-value!]
			time? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/divide"]]
		slot: stack/arguments + 1
		time?: TYPE_OF(slot) = TYPE_TIME
		slot: as red-value! float/do-math OP_DIV
		if time? [slot/header: TYPE_FLOAT]
		slot
	]
	
	multiply: func [
		return:	[red-value!]
		/local
			slot [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/multiply"]]
		slot: stack/arguments + 1
		if TYPE_OF(slot) = TYPE_TIME [
			fire [TO_ERROR(script not-related) words/_multiply datatype/push TYPE_TIME]
		]
		as red-value! float/do-math OP_MUL
	]
	
	init: does [
		datatype/register [
			TYPE_TIME
			TYPE_FLOAT
			"time!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
			null			;set-path
			INHERIT_ACTION	;compare
			;-- Scalar actions --
			INHERIT_ACTION	;absolute
			INHERIT_ACTION	;add
			:divide
			:multiply
			INHERIT_ACTION	;negate
			null			;power
			INHERIT_ACTION	;remainder
			INHERIT_ACTION	;round
			INHERIT_ACTION	;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]
