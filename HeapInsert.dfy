include "CCPR191-HeapSort-complete-30Dec18.dfy"

method {:verify true} Parent(index: nat) returns (p: int) 
	ensures p == (index - 1) / 2
	ensures p <= index
{
	p := (index - 1) / 2;
}
function {:verify true} ParentFunc(index: nat) : int 
{
	(index - 1) / 2
}

function LeftSon(index: nat) : nat 
{
    2*index+1
}

function RightSon(index: nat) : nat 
{
    2*index+2
}

predicate phSet(q: seq<int>, s: set<nat>)
	requires (forall e :: e in s ==> e < |q|)
{
	forall i,j :: i in s && j in s && AncestorIndex(i, j) ==> q[i] >= q[j]
}

predicate phAndHi(q: seq<int>, s: set<nat>, k: nat)
	requires (forall e :: e in s ==> e < |q|)
{
	(forall i,j :: i in s && j in s && AncestorIndex(i, j) ==> q[i] >= q[j]) &&
	forall j :: j in s && AncestorIndex(k, j) ==> q[k] >= q[j]
}
// // element k is a valid heap element (in the given range) with respect to its ancestors (lower indices)
predicate loSet(q: seq<int>, s: set<nat>, k: nat)
    requires k < |q| && (forall e :: e in s ==> e < |q|)
{
	forall i :: i in s && AncestorIndex(i, k) ==> q[i] >= q[k]
}
// // element k is a valid heap element (in the given range) with respect to its descendents (higher indices)
predicate hiSet(q: seq<int>, s: set<nat>, k: nat)
	requires k < |q| && (forall e :: e in s ==> e < |q|)
{
	forall j :: j in s && AncestorIndex(k, j) ==> q[k] >= q[j]
}
// the suffix q[i..] holds elements in their final (sorted) positions

function IndexSetExcept(start: nat, end: nat, except: nat): set<nat> 
{
	set i: nat | start <= i < end && i != except 
}

predicate method Guard1(a: array<int>, current: nat, parentIndex: int, heapsize: nat)
    reads a
{
	0 < current < heapsize <= a.Length && 
    0 <= parentIndex < heapsize <= a.Length &&
    a[current] > a[parentIndex]
}

predicate WhileInv(a: seq<int>, heapsize: nat, x:int, current: nat, parentIndex: int, oldA: multiset<int>)
{
    0 <= current < heapsize <= |a| && parentIndex == (current - 1) / 2 &&
	0 < heapsize <= |a| && multiset(a[..heapsize]) == oldA &&
	phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, current),current)

    // ensures 0 <= current < heapsize <= a.Length && parentIndex == (current - 1) / 2
    // ensures 0 < heapsize <= a.Length && multiset(a[..heapsize]) == oldA
    // ensures phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, parentIndex),parentIndex)
}

predicate pInv(a: seq<int>, heapsize: nat, x:int, current: nat, parentIndex: int, oldA: multiset<int>)
{
    0 <= current < heapsize <= |a| && parentIndex == (current - 1) / 2 &&
    0 < heapsize <= |a| && multiset(a[..heapsize]) == oldA
}

method HeapInsert(a: array<int>, heapsize: nat, x: int)
	requires heapsize < a.Length
	requires hp(a[..], heapsize)
	ensures hp(a[..], heapsize+1)
	ensures multiset(a[..heapsize+1]) == multiset(old(a[..heapsize])+[x])
	modifies a
{
    // Sequantial Composition
    HeapInsert1a(a, heapsize, x);	
	HeapInsert1b(a, heapsize + 1, x, multiset(old(a[..heapsize])+ [x]));	
}

method HeapInsert1a(a: array<int>, heapsize: nat, x: int)
    requires heapsize < a.Length
	requires hp(a[..], heapsize)
    ensures 0 < heapsize + 1 <= a.Length
    ensures multiset(a[..heapsize+1]) == multiset(old(a[..heapsize])+[x])
    ensures phAndHi(a[..heapsize+1], IndexSetExcept(0, heapsize+1, heapsize), heapsize)
    
    modifies a
{
    // Assignment
    Lemma1(a, heapsize, x);
    a[heapsize] := x;
}
method {:verify true} HeapInsert1b(a: array<int>, heapsize: nat, x: int, ghost oldA: multiset<int>)
    requires 0 < heapsize <= a.Length
    requires multiset(a[..heapsize]) == oldA
    requires phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, heapsize-1), heapsize-1)
    ensures hp(a[..], heapsize)
	ensures multiset(a[..heapsize]) == oldA
	modifies a
{
    // Sequantial Composition + Contract Frame
	var current, parentIndex := InitCurrAndP(a,heapsize, x);
	HeapInsert2(a, heapsize, x, current, parentIndex, oldA);
}

method {:verify true} InitCurrAndP(a: array<int>, heapsize: nat, x: int) returns(current: nat, parentIndex: int)
    requires 0 < heapsize <= a.Length
    requires phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, heapsize-1), heapsize-1)
    ensures current == heapsize - 1 && 0 <= current < a.Length && 
    parentIndex == (current - 1) / 2

{
    // Sequantial Composition + Contract Frame
	current := InitCurr(a, heapsize, x);
	parentIndex := InitParent(a, heapsize, x, current);
}

method {:verify true} InitCurr(a: array<int>, heapsize: nat, x: int) returns(current: nat)
    requires 0 < heapsize <= a.Length
    requires phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, heapsize-1), heapsize-1)
    ensures current == heapsize - 1 && 0 <= current < a.Length
{
    // Assignment
	LemmaCurr(a, heapsize, x);
	current := heapsize - 1; 
}

lemma LemmaCurr (a: array<int>, heapsize: nat, x: int)
	requires 0 < heapsize <= a.Length
    requires phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, heapsize-1), heapsize-1)
	ensures 0 <= heapsize - 1 < a.Length && heapsize - 1 == heapsize - 1
{}

method {:verify true} InitParent(a: array<int>, heapsize: nat, x: int, current: nat) returns(parent: int)
    requires 0 < heapsize <= a.Length
    requires current == heapsize - 1 && 0 <= current < a.Length 
    requires phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, heapsize-1), heapsize-1)
	ensures parent == (current - 1) / 2
{
    // Assignment
	LemmaParent(a, heapsize, x, current);
	parent := Parent(current);
}

lemma LemmaParent (a: array<int>, heapsize: nat, x: int, current: nat)
    requires 0 < heapsize <= a.Length
    requires phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, heapsize-1), heapsize-1)
    requires current == heapsize - 1 && 0 <= current < a.Length 
	ensures ParentFunc(current) == (current - 1) / 2    
{}

method {:verify true} HeapInsert2(a: array<int>, heapsize: nat, x: int, current0: nat, parentIndex0: int,ghost oldA: multiset<int>)
    requires pInv(a[..], heapsize, x, current0, parentIndex0, oldA) && current0 == heapsize - 1
    requires phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, heapsize-1), current0)
    ensures hp(a[..], heapsize)
	ensures multiset(a[..heapsize]) == oldA
	modifies a
{
	var current, parentIndex := current0, parentIndex0;
    // Iteration + Strengthen Postcondition (by Lemma4)
	while (Guard1(a, current, parentIndex,heapsize))
		invariant WhileInv(a[..], heapsize, x, current, parentIndex, multiset(old(a[..heapsize])))
		decreases current
	{ 
		current, parentIndex := LoopBody(a, heapsize, x, current, parentIndex, multiset(old(a[..heapsize])));
	}

    Lemma4(a,heapsize,x,current,parentIndex,oldA); // WhileInv && !Guard1
}

method {:verify true} LoopBody(a: array<int>, heapsize: nat, x: int, current0: nat, parentIndex0: int, ghost oldA: multiset<int>) returns (current: nat, parentIndex: int)
    requires Guard1(a, current0, parentIndex0,heapsize)
    requires WhileInv(a[..], heapsize, x, current0, parentIndex0, oldA)
    ensures pInv(a[..], heapsize, x, current, parentIndex, oldA)
    ensures phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, current),current) 
    ensures current < current0 
	modifies a
{
    // Following Assignment 
	swap(a, heapsize, x, current0, parentIndex0, oldA); 
	current, parentIndex := parentIndex0, (parentIndex0 - 1)/2;
}

method {:verify true} swap (a: array<int>, heapsize: nat, x: int, current: nat, parentIndex: int,ghost oldA: multiset<int>) 
    requires Guard1(a, current, parentIndex,heapsize)
    requires WhileInv(a[..], heapsize, x, current, parentIndex, oldA)
    // Modified WhileInv 
    ensures pInv(a[..], heapsize, x, current, parentIndex, oldA)
    ensures phAndHi(a[..heapsize], IndexSetExcept(0, heapsize, parentIndex),parentIndex)
    modifies a
{
    // Assignment
	Lemma2(a ,heapsize,x,current,parentIndex,oldA);
	a[current], a[parentIndex] := a[parentIndex], a[current];
}

lemma Lemma1 (a: array<int>, heapsize: nat, x: int)
    requires heapsize < a.Length
	requires hp(a[..], heapsize)
    ensures var newA := a[..heapsize]+[x]; 0 < heapsize + 1 <= |newA| && 
    multiset(newA) == multiset(a[..heapsize]+[x]) && 
    phAndHi(newA[..heapsize+1], IndexSetExcept(0, heapsize+1, heapsize), heapsize)
{}

lemma Lemma2(a: array<int>, heapsize: nat, x: int, current: nat, parent: int, oldA: multiset<int>)
    requires Guard1(a, current, parent,heapsize)
    requires WhileInv(a[..], heapsize, x, current, parent, oldA)

    // Modified WhileInv
    ensures pInv(a[..], heapsize, x, current, parent, oldA)
    ensures phAndHi(a[..heapsize][current := a[parent]][parent := a[current]], IndexSetExcept(0, heapsize, parent),parent)
    {
        assert parent < current;
        var newA := a[..heapsize][current := a[parent]][parent := a[current]];
        var s := IndexSetExcept(0,heapsize,parent);

        // hi 
        assert hiSet(newA[..heapsize],IndexSetExcept(0,heapsize,heapsize),parent);
        assert forall j :: j in s && AncestorIndex(parent, j) ==> newA[parent] >= newA[j];

        // ph
        assert phSet(newA[..heapsize],IndexSetExcept(0,heapsize,parent)) by {
            forall i,j | i in s && j in s && AncestorIndex(i,j) ensures newA[i] >= newA[j] {
                if (i == j) {
                    assert newA[i] >= newA[j];
                } else if (i > j) {
                    assert !AncestorIndex(i,j) ==> newA[i] >= newA[j];
                } else {
                    // i != j
                    if (i == current){
                        assert newA[i] >= newA[j];
                    } else if (j == current) {
                        assert newA[i] == a[i];
                        assert a[parent] == newA[j];
                        assert newA[i] >= newA[j] by {
                            assert AncestorIndex(i,parent) by {
                                assert AncestorIndex(i,j) && AncestorIndex(parent,j); 
                                LemmaLegacy(i,parent,j);
                            }
                            assert phSet(a[..heapsize], IndexSetExcept(0,heapsize,j)) by {
                                assert parent in IndexSetExcept(0,heapsize,j) && AncestorIndex(i,parent);
                            }
                        }
                    } else {
                        assert newA[i] >= newA[j];
                    }
                }
            }
        }
    }
lemma Lemma3(a: array<int>, heapsize: nat, x: int, current: nat, parentIndex: int, oldA: multiset<int>)
    requires 0 < heapsize <= a.Length
    requires multiset(a[..heapsize]) == oldA
    requires WhileInv(a[..], heapsize, x, current, parentIndex, oldA)
    ensures Guard1(a, current, parentIndex, heapsize) == !lo(a[..], 0, heapsize, current)
{
    assert !lo(a[..], 0, heapsize, current) == (exists j :: 0 <= j < heapsize && AncestorIndex(j, current) && a[current] > a[j]);
    // assert parentIndex == (current - 1) / 2;
    // Direction 1
    assert Guard1(a, current, parentIndex, heapsize) ==> (exists j :: 0 <= j < heapsize && AncestorIndex(j, current) && a[current] > a[j]) by {
        assert 0 < current < heapsize <= a.Length &&  0 <= parentIndex < heapsize <= a.Length && a[current] > a[parentIndex] ==> AncestorIndex(parentIndex, current) ==
        exists j :: j == parentIndex && AncestorIndex(j, current) && a[current] > a[j];
    }
    
    // Direction 2
    assert (exists j :: 0 <= j < heapsize && AncestorIndex(j, current) && a[current] > a[j]) ==> Guard1(a, current, parentIndex, heapsize) by {

        // Direction 2.1
        assert (exists j :: 0 <= j < heapsize && AncestorIndex(j, current) && a[current] > a[j]) ==> 
        0 < current < heapsize <= a.Length && 0 <= parentIndex < heapsize <= a.Length;

        // Direction 2.2
        assert (exists j :: 0 <= j < heapsize && AncestorIndex(j, current) && a[current] > a[j]) ==> a[current] > a[parentIndex] by {
            if (current == 0) {
                assert (exists j :: 0 <= j < heapsize && AncestorIndex(j, current) && a[current] > a[j]) == Guard1(a, current, parentIndex, heapsize);
            } else {
                assert current != 0 ==> 0 < current < heapsize ==> 0 <= parentIndex < heapsize;
                assert parentIndex == (current - 1) / 2;
                assert lo(a[..],0,heapsize, parentIndex);
                assert AncestorIndex(parentIndex, current);
                forall x | 0 <= x < heapsize && x != current && AncestorIndex(x, current) ensures AncestorIndex(x, parentIndex) {
                    assert parentIndex <= current;
                    assert AncestorIndex(x, current);
                    LemmaLegacy(x, parentIndex, current);
                }
            }
        }
    }
}


lemma Lemma4(a: array<int>, heapsize: nat, x:int, current: nat,parentIndex: int, oldA: multiset<int>)
	requires WhileInv(a[..], heapsize, x, current, parentIndex, oldA)
	requires !Guard1(a,current,parentIndex,heapsize)
	ensures hp(a[..], heapsize)
	ensures oldA == multiset(a[..heapsize])
{
    assert !Guard1(a,current,parentIndex,heapsize) == lo(a[..],0,heapsize,current) by {
        Lemma3(a,heapsize, x, current, parentIndex, oldA);
    }
}

lemma LemmaLegacy(x: nat, parent: nat, current: nat)
	requires AncestorIndex(x,current) && AncestorIndex(parent,current)
	requires parent == (current-1)/2 && x != current
	ensures AncestorIndex(x,parent)
	decreases parent-x
{
	assert AncestorIndex(x,parent) by {
		if (x == parent) {
			assert AncestorIndex(x,parent);
		} else {
            // x != parent
			if (AncestorIndex(LeftSon(x),current)) {
				LemmaLegacy(LeftSon(x),parent,current);
			} else {
				LemmaLegacy(RightSon(x),parent,current);
			}
		}
	}
}

method Main() {
	var a := new int[8];
	a[0] := 6;
	a[1] := 4;
	a[2] := 5;
	a[3] := 3;
	a[4] := 2;
	a[5] := 0;
	a[6] := 1;
	HeapInsert(a, 7, 8);
	print a[..];
}