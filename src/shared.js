function itemSelector(items, fn, withHeader) {
    return e => {
        let index = e.target.selectedIndex;
        var id = null;
        if(index > (withHeader ? 0 : -1)) {
            id = items[index - (withHeader ? 1 : 0)].id;
        }
        fn(id);
    };
}

export default itemSelector;
