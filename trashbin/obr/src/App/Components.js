import { PrimeReactProvider } from "primereact/api";
import { Button } from "primereact/button";
import { InputText } from "primereact/inputtext";
import { Dropdown } from "primereact/dropdown";

export const _primeReactApp = PrimeReactProvider;
export const _primeButton = Button;
export const _primeInputText = InputText;

export const _primeDropdown = Dropdown;

export function _addClassName(className) {
  return function addClassName(r) {
    if ("className" in r) {
      return { ...r, className: r.className + " " + className };
    }
    return r;
  };
}

export function _isClassName(r) {
  return "className" in r;
}
