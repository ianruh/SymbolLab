import idx2numpy
import numpy as np
from skimage.transform import resize
import numbers


class DataWrangler:

    crohme_symbols = ['0', '8', 'cos', 'forward_slash', ',', '+', 'lambda', 'mu', 'prime', 'sum', 'x',
                      '1', '9', 'Delta', 'gamma', '!', 'i', 'ldots', 'neq', 'q', 'tan', 'y', '2', 'A',
                      'd', 'geq', '(', 'infty', 'leq', 'N', 'R', 'theta', 'z', '3', 'alpha', 'div', 'G',
                      ')', 'in', 'l', 'o', 'rightarrow', 'T', '4', 'ascii_124', 'e', 'gt', '[', 'int',
                      'lim', 'phi', 'S', 'times', '5', 'beta', 'exists', 'H', ']', 'log', 'p', 'sigma',
                      'u', '6', 'b', 'f', '=', '{', 'j', 'lt', 'pi', 'sin', 'v', '7', 'C', 'forall', '-',
                      '}', 'k', 'M', 'pm', 'sqrt', 'w']
    emnist_symbols = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
                      'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']

    loaded = {}

    def __init__(self, emnist_path="./files_emnist/", crohme_path="./files_crohme/"):
        DataWrangler.symbols = DataWrangler.emnist_symbols + DataWrangler.crohme_symbols
        # Ensure there is a trailing slash in the path
        if(emnist_path[-1] != "/"):
            emnist_path += "/"
        if(crohme_path[-1] != "/"):
            crohme_path += "/"
        self.emnist_path = emnist_path
        self.crohme_path = crohme_path

    def getSymbolSet(self, symbol):
        """
        Get an entire set of symbols and store in memory. Preference is given
        to the emnist symbols.
        """
        if(symbol not in DataWrangler.symbols):
            raise ValueError("{} is not a valid symbol".format(symbol))
        flag = False  # Whether to normalize
        flag2 = False  # Whether to invert
        if(symbol in DataWrangler.emnist_symbols):
            symbol_path = "{}{}.idx".format(self.emnist_path, symbol)
        else:
            flag = True
            fattened = ["-", "(", ")", "+"]
            if(symbol in fattened):
                symbol_path = "{}{}_fat.idx".format(self.crohme_path, symbol)
            else:
                flag2 = True
                symbol_path = "{}{}.idx".format(self.crohme_path, symbol)
        array = idx2numpy.convert_from_file(symbol_path)
        if(flag):
            array = array / np.max(array)
        if(flag2):
            array = 1-array
        DataWrangler.loaded[symbol] = array
        return array

    def getRandomSymbol(self, symbol):
        """
        Get a random element of the set for symbol.
        """
        if(symbol in self.getLoadedSymbols()):
            # Already in memory
            index = np.random.choice(
                DataWrangler.loaded[symbol].shape[0], 1, replace=False)
            return DataWrangler.loaded[symbol][index].reshape((45, 45))
        else:
            # Load into memory first
            self.getSymbolSet(symbol)
            return self.getRandomSymbol(symbol)

    ########## Memory managment ###########

    def getLoadedSymbols(self):
        """
        Get list of symbols that are currently loaded in memory
        """
        return list(DataWrangler.loaded.keys())

    def unloadSymbol(self, symbol):
        """
        Unload a symbol set from memory
        """
        if(symbol not in DataWrangler.loaded.keys()):
            raise ValueError("{} is not loaded.".format(symbol))
        del DataWrangler.loaded[symbol]


class Utilities:
    @staticmethod
    def randomInt(max=100):
        return int(np.random.rand() * max + 1)

    @staticmethod
    def normal(arr, threshold=0.2):
        arr = arr / np.max(arr)
        return arr

    @staticmethod
    def shiftBBoxes(bboxes, horizontal, vertical):
        for box in bboxes:
            box["xmin"] += horizontal
            box["xmax"] += horizontal
            box["ymin"] += vertical
            box["ymax"] += vertical
        return bboxes

    @staticmethod
    def adjusted_resize(arr, shape, bboxes=None):
        """
        bboxes ==> [{
            "label": str,
            "xmin": int,
            "xmax": int,
            "ymin": int,
            "ymax": int
        }]
        """
        # Also return bounding boxes converted to new coordinates
        original_height = arr.shape[0]
        original_width = arr.shape[1]

        def convertX(x):
            return int((x/original_width)*shape[1])

        def convertY(y):
            return int((y/original_height)*shape[0])

        arr = arr * 255
        arr = np.clip(arr, 0, 255)
        try:
            arr = resize(arr, shape, preserve_range=True)
        except:
            print("Shape is zero by zero: {}".format(shape))
            raise
        arr = arr / 255

        # Convert if anything is passed
        if(bboxes is not None):
            for box in bboxes:
                box["xmin"] = convertX(box["xmin"])
                box["xmax"] = convertX(box["xmax"])
                box["ymin"] = convertY(box["ymin"])
                box["ymax"] = convertY(box["ymax"])

        return Utilities.normal(arr)

    @staticmethod
    def distance(p1, p2):
        return np.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

    @staticmethod
    def circle(x, y, width):
        pts = []
        for i in range(x-width, x+width+1):
            for j in range(y-width, y+width+1):
                if(distance((i, j), (x, y)) <= width):
                    pts.append((i, j))
        return pts

    @staticmethod
    def fan(dist, width, mult=1):
        return mult*np.cos(np.pi/2 * dist / width)

    @staticmethod
    def fatten(arr, width=2):
        """
        Increase width of marks in arr
        """
        bigger = np.zeros((arr.shape[0]+2*width, arr.shape[1]+2*width))
    #     bigger[width:arr.shape[0]+width, width:arr.shape[1]+width] = arr

        for x in range(0, arr.shape[1]):
            for y in range(0, arr.shape[0]):
                for pt in circle(x, y, width):
                    eff_x = width + pt[0]
                    eff_y = width + pt[1]
                    bigger[eff_y,
                           eff_x] += np.abs(fan(distance((x, y), (pt[0], pt[1])), width, mult=arr[y, x]))
        bigger = np.clip(bigger, 0, 1)
        return bigger

    @staticmethod
    def getBoundingBox(arr, bboxes=None):
        """
        Get a minimum size array containing all marks
        """

        top = arr.shape[0]
        bottom = 0

        left = arr.shape[1]
        right = 0

        for x in range(0, arr.shape[1]):
            for y in range(0, arr.shape[0]):
                if(arr[y, x] > 0.1):
                    if(top > y):
                        top = y
                    if(bottom < y):
                        bottom = y
                    if(left > x):
                        left = x
                    if(right < x):
                        right = x
        # Translate the bounding boxes by however much is cropped
        if(bboxes is not None):
            Utilities.shiftBBoxes(bboxes, -1*left, -1*top)

        return arr[top:bottom+1, left:right+1]


class ImageHandler:

    def __init__(self, dataWrangler):
        self.dataWrangler = dataWrangler

    def getImage(self, symbol):
        return self.dataWrangler.getRandomSymbol(str(symbol))

    def getSymbol(self, symbol):
        img = Utilities.getBoundingBox(self.getImage(symbol))
        bboxes = [{"label": symbol, "xmin": 0,
                   "xmax": img.shape[1], "ymin": 0, "ymax": img.shape[0]}]
        return img, bboxes

    def number(self, num, spacing):

        if(num is not None and num != 0):
            digits = []
            for i in range(int(np.log10(num)), -1, -1):
                digits.append(int(num/np.power(10, i) % 10))
        elif(num is not None and num == 0):
            digits = [0]

        # Get a random image of each digit
        arrs = np.zeros((len(digits), 45, 45))
        for i in range(0, len(digits)):
            arrs[i] = self.getImage(digits[i])

        # Get Bounding boxes
        boxes = []
        for char in arrs:
            boxes.append(Utilities.getBoundingBox(char))

        boundingBoxes = [{"label": str(digit)} for digit in digits]

        # Paste onto canvas
        canvas = np.zeros((45, 45*len(digits)+spacing*len(digits)))
        leftSide = 0
        for i, char in enumerate(boxes):
            height = char.shape[0]
            top = int((45/2) - (height/2))
            bottom = top + height
            left = leftSide
            right = left + char.shape[1]
            canvas[top:bottom, left:right] = char
            leftSide += char.shape[1] + spacing

            boundingBoxes[i]["xmin"] = left
            boundingBoxes[i]["xmax"] = right-1
            boundingBoxes[i]["ymin"] = top
            boundingBoxes[i]["ymax"] = bottom-1

        return Utilities.getBoundingBox(canvas, bboxes=boundingBoxes), boundingBoxes

    def string(self, name, spacing):
        """
        Returns an image of a string of ascii
        """
        imgs = []
        boundingBoxes = []
        for c in name:
            img = Utilities.getBoundingBox(self.getImage(c))
            boundingBoxes.append({"label": c, "xmin": 0,
                                  "xmax": img.shape[1]-1, "ymin": 0, "ymax": img.shape[0]-1})
            imgs.append(img)

        img = imgs[0]
        bboxes = [boundingBoxes[0]]
        for i in range(1, len(imgs)):
            newImg, newBoxes = self.mul_imp(one=img, two=imgs[i], spacing=spacing, bboxes={
                "one": bboxes, "two": [boundingBoxes[i]]})
            img = newImg
            bboxes = newBoxes

        return img, bboxes

    def comp(self, one, two, op, spacing, bboxes):
        """
        Horizontally compose two images with an operation, all three are images.

        If passing bboxes, then should be: {"one": bboxesOne, "op": bboxesOp, "two": bboxesTwo}
        """
        # List for storing bounding boxes
        boundingBoxes = []

        # Construct Canvas
        height = max(45, max(one.shape[0], two.shape[0]))
        width = one.shape[1] + 2*spacing + 45 + two.shape[1]
        canvas = np.zeros((height, width))

        # Paste one
        one_top = max(0, int(height/2 - one.shape[0]/2))
        one_bottom = one_top + one.shape[0]
        one_left = 0
        one_right = one_left + one.shape[1]
        canvas[one_top:one_bottom, one_left:one_right] = one

        boundingBoxes += Utilities.shiftBBoxes(
            bboxes["one"], one_left, one_top)

        # Paste op
        op_top = max(0, int(height/2 - op.shape[0]/2))
        op_bottom = op_top + op.shape[0]
        op_left = one_right + spacing
        op_right = op_left + op.shape[1]
        canvas[op_top:op_bottom, op_left:op_right] = op

        boundingBoxes += Utilities.shiftBBoxes(bboxes["op"], op_left, op_top)

        # Paste two
        two_top = max(0, int(height/2 - two.shape[0]/2))
        two_bottom = two_top + two.shape[0]
        two_left = op_right + spacing
        two_right = two_left + two.shape[1]
        canvas[two_top:two_bottom, two_left:two_right] = two

        boundingBoxes += Utilities.shiftBBoxes(
            bboxes["two"], two_left, two_top)

        return Utilities.getBoundingBox(canvas, bboxes=boundingBoxes), boundingBoxes

    def mul_imp(self, one, two, spacing, bboxes):
        """
        Multiply the two arrays implicitly

        bboxes must be the same format as for comp
        """
        boundingBoxes = []

        # Construct Canvas
        height = max(one.shape[0], two.shape[0])
        width = one.shape[1] + two.shape[1] + spacing
        canvas = np.zeros((height, width))

        # Paste one
        one_top = max(0, int(height/2 - one.shape[0]/2))
        one_bottom = one_top + one.shape[0]
        one_left = 0
        one_right = one_left + one.shape[1]
        canvas[one_top:one_bottom, one_left:one_right] = one

        boundingBoxes += Utilities.shiftBBoxes(
            bboxes["one"], one_left, one_top)

        # Paste two
        two_top = max(0, int(height/2 - two.shape[0]/2))
        two_bottom = two_top + two.shape[0]
        two_left = one_right + spacing
        two_right = two_left + two.shape[1]
        canvas[two_top:two_bottom, two_left:two_right] = two

        boundingBoxes += Utilities.shiftBBoxes(
            bboxes["two"], two_left, two_top)

        return Utilities.getBoundingBox(canvas, bboxes=boundingBoxes), boundingBoxes

    def power(self, base, exp, exp_scale, spacing, bboxes):
        """
        Make an exponent

        exp_scale: percentage of base height that exponent should be

        The vertical center of the exponent will be even with the top of the base.

        bboxes = {"base":bboxes, "exp":bboxes}

        """
        boundingBoxes = []

        # Resize exponent
        exp_height = max(20, int(exp_scale*base.shape[0]))
        exp_width = int(exp_height/exp.shape[0] * exp.shape[1])

        # Scale the exponent
        exp_scaled = Utilities.adjusted_resize(
            exp, (exp_height, exp_width), bboxes=bboxes["exp"])

        # Canvas dimensions
        height = base.shape[0] + \
            int(0.5 * exp_scaled.shape[0] * 1.1)  # 1.1 for margin
        width = base.shape[1] + int(exp_scaled.shape[1]) + spacing
        canvas = np.zeros((height, width))

        # Paste in the base as far down as possible so we have room uptop
        base_bottom = canvas.shape[0]-1
        base_top = base_bottom - base.shape[0]
        base_left = 0
        base_right = base_left + base.shape[1]
        canvas[base_top:base_bottom, base_left:base_right] = base

        boundingBoxes += Utilities.shiftBBoxes(
            bboxes["base"], base_left, base_top)

        # Paste in the exponent
        exp_top = base_top - int(0.5 * exp_scaled.shape[0])
        exp_bottom = exp_top + exp_scaled.shape[0]
        exp_left = base_right + spacing
        exp_right = exp_left + exp_scaled.shape[1]
        canvas[exp_top:exp_bottom, exp_left:exp_right] = exp_scaled

        boundingBoxes += Utilities.shiftBBoxes(
            bboxes["exp"], exp_left, exp_top)

        return Utilities.getBoundingBox(canvas, bboxes=boundingBoxes), boundingBoxes

    def parentheses(self, arr, spacing, bboxes):
        """
        Wrap arr in paratheses
        bboxes = [bbox]
        """

        boundingBoxes = []

        left = Utilities.getBoundingBox(getImage("("))
        right = Utilities.getBoundingBox(getImage(")"))

        # Resize left and right
        left = Utilities.adjusted_resize(left, (arr.shape[0], left.shape[1]))
        right = Utilities.adjusted_resize(
            right, (arr.shape[0], right.shape[1]))

        # Make canvas
        height = int(arr.shape[0] * 1.2)  # 1.2 for wiggle room
        width = arr.shape[1] + 2*spacing + left.shape[1] + right.shape[1]
        canvas = np.zeros((height, width))

        # Paste in Left (
        left_top = int(canvas.shape[0]/2 - left.shape[0]/2)
        left_bottom = left_top + left.shape[0]
        left_left = 0
        left_right = left_left + left.shape[1]
        canvas[left_top:left_bottom, left_left:left_right] = left

        boundingBoxes.append({"label": "(", "xmin": left_left,
                              "xmax": left_right-1, "ymin": left_top, "ymax": left_bottom-1})

        # Past in arr
        arr_top = int(canvas.shape[0]/2 - arr.shape[0]/2)
        arr_bottom = arr_top + arr.shape[0]
        arr_left = left_right + spacing
        arr_right = arr_left + arr.shape[1]
        canvas[arr_top:arr_bottom, arr_left:arr_right] = arr

        boundingBoxes += Utilities.shiftBBoxes(bboxes, arr_left, arr_top)

        # Paste in right )
        right_top = int(canvas.shape[0]/2 - right.shape[0]/2)
        right_bottom = right_top + right.shape[0]
        right_left = arr_right + spacing
        right_right = right_left + right.shape[1]
        canvas[right_top:right_bottom, right_left:right_right] = right

        boundingBoxes.append({"label": ")", "xmin": right_left,
                              "xmax": right_right-1, "ymin": right_top, "ymax": right_bottom-1})

        return Utilities.getBoundingBox(canvas, bboxes=boundingBoxes), boundingBoxes

    def fraction(self, nom, denom, spacing, bboxes):
        """
        Make fraction out of top and bottom

        If passing bboxes: bboxes = {"nom": bboxes, "denom": bboxes}
        """
        boundingBoxes = []

        bar = Utilities.getBoundingBox(getImage("-"))

        # Find width of canvas
        width = max(nom.shape[1], denom.shape[1]) + 20

        # Resize the bar
        bar_height = bar.shape[0]
        bar = Utilities.adjusted_resize(bar, (bar_height, width))

        # Make Canvas
        height = nom.shape[0] + 2*spacing + bar.shape[0] + denom.shape[0]
        canvas = np.zeros((height, width))

        # Paste Nominator
        nom_top = 0
        nom_bottom = nom_top + nom.shape[0]
        nom_left = int(canvas.shape[1]/2 - nom.shape[1]/2)
        nom_right = nom_left + nom.shape[1]
        canvas[nom_top:nom_bottom, nom_left:nom_right] = nom

        boundingBoxes += Utilities.shiftBBoxes(
            bboxes["nom"], nom_left, nom_top)

        # Paste bar
        bar_top = nom_bottom + spacing
        bar_bottom = bar_top + bar.shape[0]
        bar_left = max(0, int(canvas.shape[1]/2 - bar.shape[1]/2))
        bar_right = bar_left + bar.shape[1]
        canvas[bar_top:bar_bottom, bar_left:bar_right] = bar

        boundingBoxes.append({"label": "-", "xmin": bar_left,
                              "xmax": bar_right-1, "ymin": bar_top, "ymax": bar_bottom-1})

        # Paste denominator
        denom_top = bar_bottom + spacing
        denom_bottom = denom_top + denom.shape[0]
        denom_left = int(canvas.shape[1]/2 - denom.shape[1]/2)
        denom_right = denom_left + denom.shape[1]
        canvas[denom_top:denom_bottom, denom_left:denom_right] = denom

        boundingBoxes += Utilities.shiftBBoxes(
            bboxes["denom"], denom_left, denom_top)

        return Utilities.getBoundingBox(canvas, bboxes=boundingBoxes), boundingBoxes
