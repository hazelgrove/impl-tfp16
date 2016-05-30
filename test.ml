open OUnit2;;
open Hz_model;;
open Hz_model.Action;;
open Hz_model.Model;;
open Hz_model.Model.ZExp;;
open Hz_model.Model.ZType;;
open Hz_model.Model.HType;;
open Hz_model.Model.HExp;;



let rec stringFromHType (htype : Hz_model.Model.HType.t ) : string = match htype with
  | Num -> "num"
  | Arrow (fst,snd) -> "(" ^ stringFromHType (fst) ^ "->" ^ stringFromHType (snd) ^ ")"
  | Hole -> "H" 

let rec stringFromHExp (hexp : Model.HExp.t ) : string = match hexp with
  | Asc (hexp,htype) -> (stringFromHExp hexp) ^ ":" ^ (stringFromHType htype)
  | Var str -> str
  | Lam (var,exp) -> "λ" ^  var ^ "." ^ (stringFromHExp exp)
  | Ap (e1, e2) -> (stringFromHExp e1) ^ "(" ^ (stringFromHExp e2) ^ ")"
  | NumLit num -> string_of_int num
  | Plus (n1,n2) -> (stringFromHExp n1) ^"+"^ (stringFromHExp n2)
  | EmptyHole ->  "{}" 
  | NonEmptyHole hc -> "{" ^ (stringFromHExp hc) ^ "}"

let rec stringFromZType (ztype : Model.ZType.t ) : string = match ztype with
  | FocusedT htype -> ">" ^ stringFromHType htype ^ "<"
  | FirstArrow  (ztype, htype) -> stringFromZType ztype  ^ "->" ^ stringFromHType htype
  | SecondArrow (htype, ztype) -> stringFromHType htype ^ "->" ^ stringFromZType ztype

let rec stringFromZExp (zexp : Model.ZExp.t ) : string = match zexp with
  | FocusedE hexp -> ">" ^ stringFromHExp hexp ^ "<"
  | LeftAsc (e, asc) -> (* "LA" ^ *)  stringFromZExp e ^ ":" ^ stringFromHType asc 
  | RightAsc (e, asc) -> stringFromHExp e ^ ":" ^ stringFromZType asc
  | LamZ (var,exp) -> "λ" ^  var ^ "." ^ (stringFromZExp exp)
  | LeftAp (e1,e2) -> stringFromZExp e1 ^ stringFromHExp e2
  | RightAp (e1,e2) -> stringFromHExp e1 ^ stringFromZExp e2
  | LeftPlus (num1,num2) -> stringFromZExp num1 ^ "+" ^ stringFromHExp num2
  | RightPlus (num1,num2) -> stringFromHExp num1  ^ "+" ^ stringFromZExp num2
  | NonEmptyHoleZ e -> "{" ^ stringFromZExp e ^ "}"

let zexpToModel zexp  = 
  (zexp,HType.Num)

let assertZexpsEqual (z1,z2,a) =  assert_equal ~printer:(fun p -> Printf.sprintf "%s" p) 
    (stringFromZExp (fst z1))
    (stringFromZExp (fst (performSyn z2 a)))


let test1 test_ctxt = assert_equal (ZExp.FocusedE EmptyHole,HType.Num) (performSyn (ZExp.FocusedE (NumLit 1),Num) Del)


let arrowSelectedLeft = zexpToModel (ZExp.RightAsc ((NumLit 1),(ZType.FirstArrow (ZType.FocusedT (HType.Num),HType.Num)))) 
let arrowSelectedRight = zexpToModel (ZExp.RightAsc ((NumLit 1),(ZType.SecondArrow (HType.Num,ZType.FocusedT (HType.Num))))) 
let arrowSelectedParent = zexpToModel (ZExp.RightAsc ((NumLit 1),(ZType.FocusedT (Arrow (HType.Num,HType.Num))))) 


let test13a test_ctxt = assertZexpsEqual (arrowSelectedLeft,arrowSelectedParent,(Move FirstChild))

let test13b test_ctxt = assertZexpsEqual (arrowSelectedParent,arrowSelectedLeft,(Move Parent))

let test13c test_ctxt = assertZexpsEqual (arrowSelectedParent,arrowSelectedRight,(Move Parent))

let test13d test_ctxt = assertZexpsEqual (arrowSelectedRight,arrowSelectedLeft,(Move NextSib))

let test13e test_ctxt = assertZexpsEqual (arrowSelectedLeft,arrowSelectedRight,(Move PrevSib))


let ascSelectedParent = zexpToModel (ZExp.FocusedE (HExp.Asc (HExp.EmptyHole,HType.Hole)))
let ascSelectedFirst = zexpToModel (ZExp.LeftAsc (ZExp.FocusedE HExp.EmptyHole,HType.Hole))   
let ascSelectedSecond = zexpToModel (ZExp.RightAsc (HExp.EmptyHole,ZType.FocusedT HType.Hole))   


let test15a test_ctxt = assertZexpsEqual (ascSelectedFirst,ascSelectedParent,(Move FirstChild))
let test15b test_ctxt = assertZexpsEqual (ascSelectedParent,ascSelectedFirst,(Move Parent))
let test15c test_ctxt = assertZexpsEqual (ascSelectedParent,ascSelectedSecond,(Move Parent))
let test15d test_ctxt = assertZexpsEqual (ascSelectedSecond,ascSelectedFirst,(Move NextSib))
let test15e test_ctxt = assertZexpsEqual (ascSelectedFirst,ascSelectedSecond,(Move PrevSib))


let ascHoleType = zexpToModel (ZExp.RightAsc (HExp.EmptyHole,ZType.FocusedT HType.Hole))   
let ascArrowType = zexpToModel (ZExp.RightAsc (HExp.EmptyHole,ZType.SecondArrow(HType.Hole,ZType.FocusedT HType.Hole)))  (* ZType.FocusedT HType.Hole *)  

let ascNumType = zexpToModel (ZExp.RightAsc (HExp.EmptyHole,ZType.FocusedT HType.Num))   
let ascArrowNumType = zexpToModel (ZExp.RightAsc (HExp.EmptyHole,ZType.SecondArrow(HType.Num,ZType.FocusedT HType.Hole)))  (* ZType.FocusedT HType.Hole *)  

let test18a test_ctxt = assertZexpsEqual (ascArrowType,ascHoleType,(Construct SArrow))
let test18a2 test_ctxt = assertZexpsEqual (ascArrowNumType,ascNumType,(Construct SArrow))

let test18b test_ctxt = assertZexpsEqual (ascNumType,ascHoleType,(Construct SNum))


let numLit5 = zexpToModel (ZExp.FocusedE (HExp.NumLit 5)) 
let numLit5WithType = zexpToModel (ZExp.RightAsc ((HExp.NumLit 5),ZType.FocusedT (HType.Num))) 
let test19a test_ctxt = assertZexpsEqual (numLit5WithType,numLit5,(Construct SAsc))


let suite =
  "suite">:::
  ["test1">:: test1;
   "test13a">:: test13a;
   "test13b">:: test13b;
   "test13c">:: test13c;
   "test13d">:: test13d;
   "test13e">:: test13e;
   "test13e">:: test13e;
   "test15a">:: test15a;
   "test15b">:: test15b;
   "test15c">:: test15c;
   "test15d">:: test15d;
   "test15e">:: test15e;
   "test18a">:: test18a;
   "test18a2">:: test18a2;
   "test18b">:: test18b;
   "test19a">:: test19a;




  ]
;;


let () =
  run_test_tt_main suite;;
;;