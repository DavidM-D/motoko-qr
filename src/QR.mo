/**
 * Module     : QR.mo
 * Copyright  : 2020 DFINITY Stiftung
 * License    : Apache 2.0 with LLVM Exception
 * Maintainer : Enzo Haussecker <enzo@dfinity.org>
 * Stability  : Stable
 */

import Array "mo:base/Array";
import Block "Block";
import Common "Common";
import Generic "Generic";
import List "mo:base/List";
import Mask "Mask";
import Option "mo:base/Option";
import Symbol "Symbol";
import Version "Version";

module {

  type List<T> = List.List<T>;

  public type ErrorCorrection = Common.ErrorCorrection;
  public type Matrix = Common.Matrix;
  public type Mode = Common.Mode;
  public type Version = Version.Version;

  public func encode(
    version : Version,
    level : ErrorCorrection,
    mode : Mode,
    text : Text
  ) : ?Matrix {
    Option.bind<Version, Matrix>(
      Version.new(Version.unbox(version)),
      func _ {
        Option.bind<List<Bool>, Matrix>(
          Generic.encode(version, mode, text),
          func (data) {
            Option.bind<List<Bool>, Matrix>(
              Block.interleave(version, level, data),
              func (code) {
                let (arrays, maskRef) = Mask.generate(version, level, code);
                ?#Matrix (
                  Symbol.freeze(
                  Symbol.applyVersions(version,
                  Symbol.applyFormats(version, level, maskRef, arrays)))
                )
              }
            )
          }
        )
      }
    )
  };

  public func show(matrix : Matrix) : Text {
    let #Matrix arrays = matrix;
    Array.foldl<[Bool], Text>(func (accum1, array) {
      Array.foldl<Bool, Text>(func (accum2, bit) {
        let text = if bit "##" else "  ";
        text # accum2
      }, "\n", array) # accum1
    }, "", arrays)
  };

}
