/**
 * Module     : Numeric.mo
 * Copyright  : 2020 DFINITY Stiftung
 * License    : Apache 2.0 with LLVM Exception
 * Maintainer : Enzo Haussecker <enzo@dfinity.org>
 * Stability  : Experimental
 */

import Char "mo:base/Char";
import Common "Common";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "Nat";
import Option "mo:base/Option";
import Prim "mo:prim";
import Text "mo:base/Text";
import Util "Util";
import Version "Version";

module {

  type List<T> = List.List<T>;
  type Version = Version.Version;

  // Encode the given input text using the numeric encoding routine.
  public func encode(version : Version, text : Text) : ?List<Bool> {

    let mi = List.fromArray<Bool>([false, false, false, true]);
    let cci = Util.padLeftTo(
      Common.cciLen(version, #Numeric),
      Nat.natToBits(text.len())
    );

    let header = List.append<Bool>(mi, cci);
    let footer = List.replicate<Bool>(4, false);
    func render(body : List<Bool>) : List<Bool> {
      List.append<Bool>(header, List.append<Bool>(body, footer))
    };

    // 
    let chunks = List.chunksOf<Char>(3, Iter.toList<Char>(Text.toIter(text)));

    // 
    func step(chunk : List<Char>, accum : ?List<Bool>) : ?List<Bool> {
      switch (parse(chunk), accum) {
        case (?a, ?b) { ?List.append<Bool>(a, b) };
        case _ null
      }
    };

    // 
    Option.map<List<Bool>, List<Bool>>(
      render,
      List.foldRight<List<Char>, ?List<Bool>>(chunks, ?null, step)
    )

  };

  func parse(chunk : List<Char>) : ?List<Bool> {

    // 
    let p = switch (List.len<Char>(chunk)) {
      case 3 ?10;
      case 2 ?07;
      case 1 ?04;
      case _ null
    };

    //
    let n = List.foldLeft<Char, ?Nat>(chunk, ?0, func (char, accum) {
      if (Char.isDigit(char)) {
        Option.map<Nat, Nat>(func (a) {
          let b = Prim.word32ToNat(
            Prim.charToWord32(char) - Prim.charToWord32('0')
          );
          10 * a + b
        }, accum)
      } else {
        null
      }
    });

    // 
    switch (p, n) {
      case (?a, ?b) { ?Util.padLeftTo(a, Nat.natToBits(b)) };
      case _ null
    }

  };

}
