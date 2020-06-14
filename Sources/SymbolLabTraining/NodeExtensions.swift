//
//  File.swift
//  
//
//  Created by Ian Ruh on 6/2/20.
//
import SymbolLab

extension Number {
    /**
     Function get's the image of the node.
     */
    public func getImage(using imageHandler: ImageHandler) -> EquationImage? {
        return imageHandler.number(self.value)
    }
}

extension Variable {
    /**
     Function get's the image of the node.
     */
    public func getImage(using imageHandler: ImageHandler) -> EquationImage? {
        return imageHandler.string(self.string)
    }
}

extension Assign {
    /**
     Function get's the image of the node.
     */
    public func getImage(using imageHandler: ImageHandler) -> EquationImage? {
        let leftImageOpt = SymbolLabTraining.getImage(node: self.left, using: imageHandler)
        let rightImageOpt = SymbolLabTraining.getImage(node: self.right, using: imageHandler)
        let operationSymbol = imageHandler.getSymbol(of: self.identifier)
        guard let leftImage = leftImageOpt else {
            return nil
        }
        guard let rightImage = rightImageOpt else {
            return nil
        }
        return imageHandler.compose(left: leftImage, right: rightImage, operation: operationSymbol)
    }
}

extension Negative {
    /**
     Function get's the image of the node.
     */
    public func getImage(using imageHandler: ImageHandler) -> EquationImage? {
        let argImageOpt = SymbolLabTraining.getImage(node: self.argument, using: imageHandler)
        guard let argImage = argImageOpt else {
            return nil
        }
        let negativeImage = imageHandler.getSymbol(of: "-")
        return imageHandler.multiplyImplicitly(left: negativeImage, right: argImage)
    }
}

extension Decimal {
    /**
     Function get's the image of the node.
     */
    public func getImage(using imageHandler: ImageHandler) -> EquationImage? {
        let leftImageOpt = SymbolLabTraining.getImage(node: self.left, using: imageHandler)
        let rightImageOpt = SymbolLabTraining.getImage(node: self.right, using: imageHandler)
        let operationSymbol = imageHandler.getSymbol(of: self.identifier)
        guard let leftImage = leftImageOpt else {
            return nil
        }
        guard let rightImage = rightImageOpt else {
            return nil
        }
        return imageHandler.compose(left: leftImage, right: rightImage, operation: operationSymbol)
    }
}
