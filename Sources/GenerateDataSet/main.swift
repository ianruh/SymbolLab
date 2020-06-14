//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/29/20.
//

import SymbolLab
import SymbolLabTraining
import PythonKit

let plt = Python.import("matplotlib.pyplot")
let np = Python.import("numpy")

// Set up Python
let dataWrangler = DataWrangler(emnistPath: "/Users/ianruh/Dev/SymbolLab/Data/files_emnist/", crohmePath: "/Users/ianruh/Dev/SymbolLab/Data/files_crohme/")
let imageHandler = ImageHandler(options: ImageGeneratorOptions(), dataWrangler: dataWrangler)

// Set up parser
let parser = Parser()

// Create Node
let node = parser.parse(cString: "x=4")!

let tuple: EquationImage? = getImage(node: node, using: imageHandler)

if let image = tuple?.image {
    plt.imsave("/Users/ianruh/Downloads/num.png", image)
} else {
    print("Found nil")
}
