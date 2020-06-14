//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/9/20.
//

import PythonKit
import SymbolLab

private let PythonUtilities = Python.import("PythonUtilities.data_wrangler")

public class DataWrangler {
    
    /**
     The python object that is the data wrangler instance.
     */
    internal var dataWrangler: PythonObject
    
    /**
     List  of the symbols being  retrieved from crohme
     */
    public var crohmeSymbols: [String] {
        return self.dataWrangler.crohme_symbols.map({$0.description})
    }
    
    /**
     List of symbols being retrieved from emnist
     */
    public var emnistSymbols: [String] {
        return self.dataWrangler.emnist_symbols.map({$0.description})
    }
    
    /**
     Initializer  that takes the paths to the  data files.
     */
    public init(emnistPath: String, crohmePath: String) {
        self.dataWrangler = PythonUtilities.DataWrangler(emnistPath, crohmePath)
    }
    
    /**
     Get a random element of the given symbol.
     */
    public func getRandom(symbol: String) -> PythonObject {
        return self.dataWrangler.getRandomSymbol(symbol)
    }
    
    /**
     Get a list of  the loaded symbols.
     */
    public func getLoadedSymbols() -> PythonObject {
        return self.dataWrangler.getLoadedSymbols()
    }
    
    /**
     Remove a symbol from the cache of symbols.
     */
    public func unload(symbol: String) {
        self.dataWrangler.unloadSymbol(symbol)
    }
}

public class ImageHandler {
    /**
     The python object that is the image handler instance.
     */
    internal var imageHandler: PythonObject
    
    internal var options: ImageGeneratorOptions
    
    /**
     Initializer for an image  handler. Takes the options and the DataWrangler (data source).
     */
    public init(options: ImageGeneratorOptions, dataWrangler: DataWrangler) {
        self.imageHandler = PythonUtilities.ImageHandler(dataWrangler.dataWrangler)
        self.options = options
    }
    
    /**
     Get an image of a specific variable.
     */
    public func getImage(of name: String) -> PythonObject {
        return self.imageHandler.getImage(name)
    }
    
    /**
     Get an image and bounding box of a specific variable.
     */
    public func getSymbol(of name: String) -> EquationImage {
        let tuple = self.imageHandler.getSymbol(name)
        return (tuple[0], tuple[1])
    }
    
    /**
     Get an image of a number.
     */
    public func number(_ num: Int) -> EquationImage {
        let tuple = self.imageHandler.number(num, self.options.numberSpacing)
        return (tuple[0], tuple[1])
    }
    
    /**
     Get an image of a string.
     */
    public func string(_ name: String)  -> EquationImage {
        let tuple = self.imageHandler.string(name, self.options.stringSpacing)
        return (tuple[0], tuple[1])
    }
    
    /**
     Compose three images.
     */
    public func compose(left: EquationImage, right: EquationImage, operation: EquationImage) -> EquationImage {
        let bboxDict: PythonObject = ["one": left.boundingBoxes, "op": operation.boundingBoxes ,"two": right.boundingBoxes]
        let tuple = self.imageHandler.comp(left.image, right.image, operation.image, self.options.compSpacing, bboxDict)
        return (tuple[0], tuple[1])
    }
    
    /**
     Multiply two images implicitly.
     */
    public func multiplyImplicitly(left: EquationImage, right: EquationImage) -> EquationImage {
        let bboxes: PythonObject = ["one": left.boundingBoxes, "two": right.boundingBoxes]
        let tuple = self.imageHandler.mul_imp(left.image, right.image, self.options.numberSpacing, bboxes)
        return (tuple[0], tuple[1])
    }
    
    /**
     Power two operations.
     */
    public func power(base: EquationImage, exponent: EquationImage) -> EquationImage {
        let bboxes: PythonObject = ["base": base.boundingBoxes, "exp": base.boundingBoxes]
        let tuple = self.imageHandler.power(base.image, exponent.image, self.options.exponentScale, self.options.exponentSpacing, bboxes)
        return (tuple[0], tuple[1])
    }
    
    /**
     Put parentheses  around an argument.
     */
    public func parentheses(_ arg: EquationImage) -> EquationImage {
        let tuple = self.imageHandler.parentheses(arg.image, self.options.parenthesesSpacing, arg.boundingBoxes)
        return (tuple[0], tuple[1])
    }
    
    /**
     Make a fraction.
     */
    public func fraction(nominator: EquationImage, denominator: EquationImage) -> EquationImage {
        let bboxes: PythonObject = ["nom": nominator.boundingBoxes, "denom": denominator.boundingBoxes]
        let tuple = self.imageHandler.fraction(nominator.image, denominator.image, self.options.fractionSpacing, bboxes)
        return (tuple[0], tuple[1])
    }
}
