#a function to count how many items there are, whether its an array, a collection, or actually just
# a single no array/non list/non collection object in which case it would be 1
function count ($InputObject)
{
 if ($inputobject -eq $Null ) { return 0}
 if ($inputobject -is [system.array]) { return $inputobject.length }
 if ($inputobject -is [system.collections.ICollection] -or 
     $inputobject -is [system.collections.IList] )  { return $inputobject.count }
 #strings are ienumerable, they also have a length, but i think we want to treat 1 string as one object
 if ($inputobject -is [string]) { return 1 }
 #-1 to show that it is enumerable, but we can't know its length, it could be infinate, 
 #or take a long time even to enumerate without going over 
 if ($inputobject -is [system.collections.IEnumerable]) { return -1 }
 #otherwise just return 1
 return 1
}
count (get-process)
count (1,2,3)
count "hello"
count 3

$a = new-object system.collections.arraylist
[void] $a.add(4);
[void] $a.add("yo");

count $a




