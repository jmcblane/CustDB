#!/usr/bin/ruby

require 'sqlite3'
require 'fox16'
include Fox

if File.exists?("./customers.db") == false
    db = SQLite3::Database.new "./customers.db"
    db.execute("create virtual table customers using fts5(fname, lname, addr, ph1, ph2, email, cityzip, identifier);")
    db.execute("create virtual table jobs using fts5(custid unindexed, desc, notes, active unindexed, identifier);")
end
    
DB = SQLite3::Database.new "./customers.db"

class Customers < FXMainWindow
    def initialize(app)
        super(app, "Customer Database", :width => 300, :height => 400)

        mainframe = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)
        
        row1 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        @which_search = FXDataTarget.new(0)

        spacer = FXHorizontalFrame.new(row1, LAYOUT_FILL_X)
        custie_btn = FXRadioButton.new(row1, "Customers", @which_search, FXDataTarget::ID_OPTION)
        job_btn = FXRadioButton.new(row1, "Jobs", @which_search, FXDataTarget::ID_OPTION + 1)
        active_btn = FXRadioButton.new(row1, "Active Jobs", @which_search, FXDataTarget::ID_OPTION + 2)
        spacer = FXHorizontalFrame.new(row1, LAYOUT_FILL_X)

        row2 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        @search_txt = FXTextField.new(row2, 20, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        search_btn = FXButton.new(row2, "Search", :padRight => 5, :padLeft => 5, :padTop => 2, :padBottom => 2)

        row3 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        spacer = FXFrame.new(row3, LAYOUT_FILL_X)
        info_btn = FXButton.new(row3, "Info", :padRight => 25, :padLeft => 25, :padTop => 5, :padBottom => 5)
        spacer = FXFrame.new(row3, LAYOUT_FILL_X)
        new_btn = FXButton.new(row3, "New", :padRight => 25, :padLeft => 25, :padTop => 5, :padBottom => 5)
        spacer = FXFrame.new(row3, LAYOUT_FILL_X)

        row4 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL|FRAME_SUNKEN,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        @customers_list = FXList.new(row4, :opts => LAYOUT_FILL|LIST_SINGLESELECT)

        @customers_list.connect(SEL_SELECTED) do |x, y, z|
            @which_result = @customers_list.getItemData(z)
            @jobid = @customers_list.getItemData(z)[1] if @which_result != nil
        end

        @customers_list.connect(SEL_DOUBLECLICKED) { self.results_info }

        search_btn.connect (SEL_COMMAND) { self.search_items }

        info_btn.connect (SEL_COMMAND) { self.results_info }
        new_btn.connect (SEL_COMMAND) { self.new_customer }

        self.load_customers
    end

    def search_items
        return if @search_txt.text == "*"
        return self.load_customers if @search_txt.text == "" and @which_search.value == 0
        @customers_list.clearItems

        if @which_search.value == 0
            begin
                results = DB.execute("select fname, lname, ph1, rowid from customers where customers match '#{@search_txt}';")
            rescue
                results = []
            end

            if results.length > 0
                results.each { |i| @customers_list.appendItem("#{i[1]}, #{i[0]}  --  #{i[2]}", nil, [i[3], nil]) }
            else
                @customers_list.appendItem("No results.")
            end

        elsif @which_search.value == 1 or @which_search.value == 2
            begin
                results = DB.execute("select custid, desc, active, rowid from jobs where jobs match '#{@search_txt}';") if @which_search.value == 1
                results = DB.execute("select custid, desc, active, rowid from jobs where active == 1;") if @which_search.value == 2
            rescue
                results = []
            end

            if results.length > 0
                for i in results
                    customer = DB.execute("select fname, lname from customers where rowid == #{i[0]};")[0]
                    name = "#{customer[1]}, #{customer[0]}"
                    desc = i[1]
                    desc = "#{i[1]} -- $$" if @which_search.value == 1 and i[2] == 1
                    @customers_list.appendItem("#{name}  --  #{desc}", nil, [i[0], i[3]])
                end
            else
                @customers_list.appendItem("No results.")
            end
        end
    end

    def results_info
        return if @which_result == nil
        info_win = Customer_Jobs.new(app, @which_result[0])
        info_win.create
        info_win.edit_job(@which_result[1]) if @which_result[1] != nil
    end

    def load_customers
        @customers_list.clearItems
        customers = DB.execute("select lname, fname, rowid, identifier from customers;")
        for i in customers
            active_jobs = DB.execute("select * from jobs where custid == #{i[2]} and active == 1")
            name = "#{i[0]}, #{i[1]}"
            name += "  --  $$" if active_jobs.length > 0
            @customers_list.appendItem(name, nil, [i[2], nil])
        end
        if @customers_list.numItems > 0
            @customers_list.selectItem(0)
            @customers_list.sortItems
            @which_result = @customers_list.getItemData(0)
        else
            @which_result = nil
        end
    end

    def new_customer
        win2 = Customer_Jobs.new(app, nil); win2.create
        # win2.connect(SEL_CLOSE) { win2.close; self.load_customers }
        # Not great since we merged the boxes into one.
    end

    def create
        super; show(PLACEMENT_SCREEN)
    end
end

class Customer_Jobs < FXMainWindow
    def initialize(app, custid)
        @custid = custid
        @custname = DB.execute("select fname, lname from customers where rowid == #{@custid};")[0].join(" ") if @custid != nil
        @custname = "NEW CUSTOMER" if @custid == nil

        super(app, "Customer: #{@custname}", :width=> 450, :height => 400)

        mainframe = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y, 
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        row1 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X, 
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        column1 = FXVerticalFrame.new(row1, LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH, 
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        fname_lbl = FXLabel.new(column1, "First name:")
        lname_lbl = FXLabel.new(column1, "Last name:", :padTop => 7)
        addr_lbl = FXLabel.new(column1, "Address:", :padTop => 7)
        cityzip_lbl = FXLabel.new(column1, "City, Zip:", :padTop => 7)
        ph1_lbl = FXLabel.new(column1, "Phone 1:", :padTop => 7)
        ph2_lbl = FXLabel.new(column1, "Phone 2:", :padTop => 7)
        email_lbl = FXLabel.new(column1, "E-mail:", :padTop => 7)

        column2 = FXVerticalFrame.new(row1, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        @fname_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @lname_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @addr_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @cityzip_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @ph1_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @ph2_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @email_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        separator = FXSeparator.new(mainframe, LAYOUT_FILL_X|SEPARATOR_GROOVE)

        column3 = FXVerticalFrame.new(row1, LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH|PACK_UNIFORM_HEIGHT,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        save_btn = FXButton.new(column3, "Save")
        delete_btn = FXButton.new(column3, "Delete")
        spacer = FXFrame.new(column3, LAYOUT_FILL_Y)
        spacer = FXFrame.new(column3, LAYOUT_FILL_Y)
        id_lbl = FXLabel.new(column3, "Cust ID:")
        @custid_txt = FXTextField.new(column3, 7, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)

        delete_btn.connect (SEL_COMMAND) do
            check = FXMessageBox.question(app, MBOX_YES_NO, "Are you sure?", "Are you sure? This can't be undone!")
            if check == MBOX_CLICKED_YES
                DB.execute("delete from customers where rowid == #{@custid}")
                DB.execute("delete from jobs where custid == #{@custid}")
            end
            self.close(true)
        end

        row2 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        column1 = FXVerticalFrame.new(row2, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        @job_list = FXList.new(column1, :opts => LAYOUT_FILL|LIST_SINGLESELECT, :width => 315, :height => 175)

        @job_list.connect(SEL_SELECTED) { |x, y, z| @jobid = @job_list.getItemData(z) }

        @job_list.connect(SEL_DOUBLECLICKED) { self.edit_job(@jobid) }

        column2 = FXVerticalFrame.new(row2, LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        new_btn = FXButton.new(column2, "New")
        edit_btn = FXButton.new(column2, "Edit")
        active_button = FXButton.new(column2, "Active")
        delete_button = FXButton.new(column2, "Delete")
        spacer = FXFrame.new(column2, LAYOUT_FILL_Y)

        new_btn.disable if @custid == nil
        edit_btn.disable if @custid == nil
        active_button.disable if @custid == nil
        delete_button.disable if @custid == nil
        delete_btn.disable if @custid == nil

        new_btn.connect (SEL_COMMAND) { self.edit_job(nil) }

        edit_btn.connect (SEL_COMMAND) { self.edit_job(@jobid) }

        save_btn.connect (SEL_COMMAND) { self.save_custie }

        active_button.connect (SEL_COMMAND) do
            DB.execute("update jobs set active = NOT active where rowid == #{@jobid};")
            self.load_jobs
        end

        delete_button.connect (SEL_COMMAND) do
            check = FXMessageBox.question(app, MBOX_YES_NO, "Are you sure?", "Are you sure? This can't be undone!")
            if check == MBOX_CLICKED_YES
                DB.execute("delete from jobs where rowid == #{@jobid}")
            end
            self.load_jobs
        end

        self.load_custie
        self.load_jobs
    end

    def load_custie
        return if @custid == nil
        fields = [@fname_txt, @lname_txt, @addr_txt, @ph1_txt, @ph2_txt, @email_txt, @cityzip_txt, @custid_txt]
        info = DB.execute("select fname, lname, addr, ph1, ph2, email, cityzip, identifier from customers where rowid == #{@custid};")[0]
        (0..7).each { |x| fields[x].setText(info[x], true) }
    end

    def save_custie
        fields = {"fname" => @fname_txt, "lname" => @lname_txt, "addr" => @addr_txt,
                  "ph1" => @ph1_txt, "ph2" => @ph2_txt, "email" => @email_txt, "cityzip" => @cityzip_txt, "identifier" => @custid_txt}
        if @custid == nil
            DB.execute("insert into customers (fname, lname, addr, ph1, ph2, email, cityzip, identifier) values ('#{@fname_txt}', '#{@lname_txt}', '#{@addr_txt}', '#{@ph1_txt}', '#{@ph2_txt}', '#{@email_txt}', '#{@cityzip_txt}', '#{@custid_txt}');")
        else
            fields.each { |x, y| DB.execute("update customers set #{x} = '#{y}' where rowid == #{@custid};") }
        end
        self.close(true)
    end

    def load_jobs
        return if @custid == nil
        @job_list.clearItems
        jobs = DB.execute("select desc, rowid, active, identifier from jobs where custid == #{@custid};")
        jobs.reverse!
        for i in jobs
            desc = "#{i[3]}  --  #{i[0]}"
            desc += "  --  $$" if i[2] == 1
            @job_list.appendItem(desc, nil, i[1])
        end
        if @job_list.numItems > 0
            @job_list.selectItem(0)
            @jobid = @job_list.getItemData(0)
        else
            @jobid = nil
        end
    end

    def edit_job(job)
        job_win = Job_Edit.new(app, @custid, job); job_win.create
        job_win.connect(SEL_CLOSE) { job_win.close; self.load_jobs }
    end

    def create
        super; show(PLACEMENT_SCREEN)
    end
end

class Job_Edit < FXMainWindow
    def initialize(app, custid, jobid)
        @custid = custid
        @jobid = jobid
        @custname = DB.execute("select fname, lname from customers where rowid == #{@custid};")[0].join(" ")

        super(app, "Edit Job", :width=> 350, :height => 300)

        mainframe = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        row1 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)
        
        column1 = FXVerticalFrame.new(row1, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        fname_lbl = FXLabel.new(column1, "Customer:", :padTop => 3)
        desc_lbl = FXLabel.new(column1, "Job Desc:", :padTop => 6)

        column2 = FXVerticalFrame.new(row1, LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        subrow = FXHorizontalFrame.new(column2, LAYOUT_FILL_X,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        name_lbl = FXLabel.new(subrow, @custname)
        spacer = FXFrame.new(subrow, LAYOUT_FILL_X)
        jobid_lbl = FXLabel.new(subrow, "Job ID:", :padTop => 3)
        @jobid_txt = FXTextField.new(subrow, 7)

        @desc_txt = FXTextField.new(column2, 30, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)

        midrow = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        notes_lbl = FXLabel.new(midrow, "Notes:")
        spacer = FXFrame.new(midrow, LAYOUT_FILL_X)
        @active_chk = FXCheckButton.new(midrow, "Active?")
        btn_save = FXButton.new(midrow, "Save")

        btn_save.connect (SEL_COMMAND) { self.save_job_info }

        row2 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL|FRAME_SUNKEN,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)
        @notes_box = FXText.new(row2, :opts => LAYOUT_FILL|TEXT_WORDWRAP)

        self.load_job_info
    end

    def load_job_info
        @active_chk.setCheck(true); return if @jobid == nil
        info = DB.execute("select desc, notes, active, identifier from jobs where rowid == #{@jobid};")[0]
        @desc_txt.setText(info[0], true)
        @notes_box.setText(info[1], true)
        @jobid_txt.setText(info[3], true)
        @active_chk.setCheck(false) if info[2] == 0
    end

    def save_job_info
        fields = {"desc" => @desc_txt, "notes" => @notes_box, "active" => @active_chk.checkState, "identifier" => @jobid_txt}
        if @jobid == nil
            DB.execute("insert into jobs (custid, desc, notes, active, identifier) values (#{@custid}, '#{@desc_txt}', '#{@notes_box}', #{@active_chk.checkState}, '#{@jobid_txt}');")
        else
            for x, y in fields
                if x == "active"
                    DB.execute("update jobs set #{x} = #{y} where rowid == #{@jobid};")
                else
                    DB.execute("update jobs set #{x} = '#{y}' where rowid == #{@jobid};")
                end
            end
        end
        self.close(true)
    end


    def create
        super; show(PLACEMENT_SCREEN)
    end

end

if __FILE__ == $0
    FXApp.new do |app|
        Customers.new(app)
        app.create
        app.run
    end
end
