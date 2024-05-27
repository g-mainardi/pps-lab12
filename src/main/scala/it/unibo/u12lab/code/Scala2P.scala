package it.unibo.u12lab.code

import alice.tuprolog.*

object Scala2P:

  def extractTerm(solveInfo:SolveInfo, i:Integer): Term =
    solveInfo.getSolution.asInstanceOf[Struct].getArg(i).getTerm

  def extractTerm(solveInfo:SolveInfo, s:String): Term =
    solveInfo.getTerm(s)

  given Conversion[String, Term] = Term.createTerm(_)
  given Conversion[Seq[_], Term] =  _.mkString("[",",","]")
  given Conversion[String, Theory] = new Theory(_);

  def mkPrologEngine(theory: Theory): Term => LazyList[SolveInfo] =
    val engine = Prolog()
    engine.setTheory(theory)

    goal => new Iterable[SolveInfo]{

      override def iterator = new Iterator[SolveInfo]{
        var solution: Option[SolveInfo] = Some(engine.solve(goal))

        override def hasNext = solution.isDefined &&
                              (solution.get.isSuccess || solution.get.hasOpenAlternatives)

        override def next() =
          try solution.get
          finally solution = if (solution.get.hasOpenAlternatives) Some(engine.solveNext()) else None
      }
    }.to(LazyList)


  def solveWithSuccess(engine: Term => LazyList[SolveInfo], goal: Term): Boolean =
    engine(goal).map(_.isSuccess).headOption == Some(true)

  def solveOneAndGetTerm(engine: Term => LazyList[SolveInfo], goal: Term, term: String): Term =
    engine(goal).headOption.map(extractTerm(_,term)).get


object TryScala2P extends App:
  import Scala2P.{*, given}

  val engine: Term => LazyList[SolveInfo] = mkPrologEngine("""
    member([H|T],H,T).
    member([H|T],E,[H|T2]):- member(T,E,T2).
    permutation([],[]).
    permutation(L,[H|TP]) :- member(L,H,T), permutation(T,TP).
  """)

  engine("permutation([1,2,3],L)") foreach (println(_))
  // permutation([1,2,3],[1,2,3]) ... permutation([1,2,3],[3,2,1])

  val input = new Struct("permutation",(1 to 20), Var())
  engine(input) map (extractTerm(_,1)) take 100 foreach (println(_))
  // [1,2,3,4,..,20] ... [1,2,..,15,20,16,18,19,17]
