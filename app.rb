#!/usr/bin/ruby

require 'sqlite3'
require 'fox16'
include Fox

DB = SQLite3::Database.new "./cust.db"

class Customers < FXMainWindow
    def initialize(app)
        app = app
        super(app, "Customer Database", :width=> 275, :height => 250)

        mainframe = FXHorizontalFrame.new(self,
            LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        frame1 = FXHorizontalFrame.new(mainframe,
            FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        @customer_list = FXList.new(frame1,
                        :opts => LAYOUT_FILL|LIST_SINGLESELECT,
                                   :width => 200)

        @customer_list.connect(SEL_SELECTED) do |x, y, z|
            @custid = @customer_list.getItemData(z)
        end

        @customer_list.connect(SEL_DOUBLECLICKED) do
            self.customer_info
        end


        frame2 = FXVerticalFrame.new(mainframe,
            LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        info_btn = FXButton.new(frame2, "Info")
        new_btn = FXButton.new(frame2, "New")
        delete_btn = FXButton.new(frame2, "Delete")
        spacer = FXFrame.new(frame2, LAYOUT_FILL_Y)

        info_btn.connect (SEL_COMMAND) do
            self.customer_info
        end

        new_btn.connect (SEL_COMMAND) do
            self.new_customer
        end

        delete_btn.connect (SEL_COMMAND) do
            check = FXMessageBox.question(app, MBOX_YES_NO, "Are you sure?", "Are you sure? This can't be undone!")
            if check == MBOX_CLICKED_YES
                DB.execute("delete from customers where custid == #{@custid}")
                DB.execute("delete from jobs where custid == #{@custid}")
            end
            self.load_customers
        end


        self.load_customers
    end

    def load_customers
        @customer_list.clearItems
        customers = DB.execute("select lname, fname, custid from customers;")
        for i in customers
            active_jobs = DB.execute("select * from jobs where custid == #{i[2]} and active == 1")
            name = "#{i[0]}, #{i[1]}"
            name += "  $$" if active_jobs.length > 0
            @customer_list.appendItem(name, nil, i[2])
        end
        if @customer_list.numItems > 0
            @customer_list.selectItem(0)
            @custid = @customer_list.getItemData(0)
            @customer_list.sortItems
        else
            @custid = nil
        end
    end

    def customer_info
        win2 = Customer_Jobs.new(app, @custid)
        win2.create
    end

    def new_customer
        win2 = Customer_Jobs.new(app, nil)
        win2.create
        win2.connect(SEL_CLOSE) do
            win2.close
            self.load_customers
        end
    end

    def create
        super
        show(PLACEMENT_SCREEN)
    end
end

class Customer_Jobs < FXMainWindow
    def initialize(app, custid)
        app = app
        @custid = custid
        @custname = DB.execute("select fname, lname from customers where custid == #{@custid};")[0].join(" ") if @custid != nil
        @custname = "NEW CUSTOMER" if @custid == nil

        super(app, "Customer: #{@custname}", :width=> 400, :height => 400)

        mainframe = FXVerticalFrame.new(self,
            LAYOUT_FILL_X|LAYOUT_FILL_Y, 
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        row1 = FXHorizontalFrame.new(mainframe,
            LAYOUT_FILL_X, 
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        column1 = FXVerticalFrame.new(row1,
            LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH, 
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)
        fname_lbl = FXLabel.new(column1, "First name:")
        lname_lbl = FXLabel.new(column1, "Last name:", :padTop => 7)
        addr_lbl = FXLabel.new(column1, "Address:", :padTop => 7)
        cityzip_lbl = FXLabel.new(column1, "City, Zip:", :padTop => 7)
        ph1_lbl = FXLabel.new(column1, "Phone 1:", :padTop => 7)
        ph2_lbl = FXLabel.new(column1, "Phone 2:", :padTop => 7)
        email_lbl = FXLabel.new(column1, "E-mail:", :padTop => 7)

        column2 = FXVerticalFrame.new(row1,
            LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)
        @fname_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @lname_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @addr_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @cityzip_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @ph1_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @ph2_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
        @email_txt = FXTextField.new(column2, 26, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)

        column3 = FXVerticalFrame.new(row1,
            LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)
        save_btn = FXButton.new(column3, "Save")

        row2 = FXHorizontalFrame.new(mainframe,
            LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        column1 = FXVerticalFrame.new(row2,
            FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        @job_list = FXList.new(column1,
                    :opts => LAYOUT_FILL|LIST_SINGLESELECT,
                    :width => 315, :height => 175)

        @job_list.connect(SEL_SELECTED) do |x, y, z|
            @jobid = @job_list.getItemData(z)
        end

        @job_list.connect(SEL_DOUBLECLICKED) do
            self.edit_job
        end

        column2 = FXVerticalFrame.new(row2,
            LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH,
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

        new_btn.connect (SEL_COMMAND) do
            self.new_job
        end

        edit_btn.connect (SEL_COMMAND) do
            self.edit_job
        end

        save_btn.connect (SEL_COMMAND) do
            self.save_custie
        end

        active_button.connect (SEL_COMMAND) do
            DB.execute("update jobs set active = NOT active where jobid == #{@jobid};")
            self.load_jobs
        end

        delete_button.connect (SEL_COMMAND) do
            check = FXMessageBox.question(app, MBOX_YES_NO, "Are you sure?", "Are you sure? This can't be undone!")
            if check == MBOX_CLICKED_YES
                DB.execute("delete from jobs where jobid == #{@jobid}")
            end
            self.load_jobs
        end

        self.load_custie
        self.load_jobs
    end

    def load_custie
        return if @custid == nil
        fields = [@fname_txt, @lname_txt, @addr_txt, @ph1_txt, @ph2_txt, @email_txt, @cityzip_txt]
        info = DB.execute("select * from customers where custid == #{@custid};")[0]
        x = 1
        for i in fields
            i.setText(info[x], true)
            x += 1
        end
    end

    def save_custie
        fields = {"fname" => @fname_txt, "lname" => @lname_txt, "addr" => @addr_txt,
                  "ph1" => @ph1_txt, "ph2" => @ph2_txt, "email" => @email_txt, "cityzip" => @cityzip_txt}
        if @custid == nil
            DB.execute("insert into customers (fname, lname, addr, ph1, ph2, email, cityzip) values ('#{@fname_txt}', '#{@lname_txt}', '#{@addr_txt}', '#{@ph1_txt}', '#{@ph2_txt}', '#{@email_txt}', '#{@cityzip_txt}');")
        else
            for x, y in fields
                DB.execute("update customers set #{x} = '#{y}' where custid == #{@custid};")
            end
        end
        self.close(true)
    end

    def load_jobs
        return if @custid == nil
        @job_list.clearItems
        jobs = DB.execute("select desc, jobid, active from jobs where custid == #{@custid};")
        jobs.reverse!
        for i in jobs
            desc = i[0]
            desc += "  $$" if i[2] == 1
            @job_list.appendItem(desc, nil, i[1])
        end
        if @job_list.numItems > 0
            @job_list.selectItem(0)
            @jobid = @job_list.getItemData(0)
        else
            @jobid = nil
        end
    end

    def new_job
        job_win = Job_Edit.new(app, @custid, nil)
        job_win.create
        job_win.connect(SEL_CLOSE) do
            job_win.close
            self.load_jobs
        end
    end

    def edit_job
        job_win = Job_Edit.new(app, @custid, @jobid)
        job_win.create
        job_win.connect(SEL_CLOSE) do
            job_win.close
            self.load_jobs
        end
    end

    def create
        super
        show(PLACEMENT_SCREEN)
    end
end

class Job_Edit < FXMainWindow
    def initialize(app, custid, jobid)
        @custid = custid
        @jobid = jobid
        @custname = DB.execute("select fname, lname from customers where custid == #{@custid};")[0].join(" ")

        super(app, "Edit Job", :width=> 350, :height => 300)

        mainframe = FXVerticalFrame.new(self,
            LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        row1 = FXHorizontalFrame.new(mainframe,
            LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)
        
        column1 = FXVerticalFrame.new(row1,
            LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        fname_lbl = FXLabel.new(column1, "Customer:")
        desc_lbl = FXLabel.new(column1, "Job Desc:", :padTop => 5)

        column2 = FXVerticalFrame.new(row1,
            LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)
        name_lbl = FXLabel.new(column2, @custname)
        @desc_txt = FXTextField.new(column2, 30, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)

        midrow = FXHorizontalFrame.new(mainframe,
            LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)
        notes_lbl = FXLabel.new(midrow, "Notes:")
        spacer = FXFrame.new(midrow, LAYOUT_FILL_X)
        @active_chk = FXCheckButton.new(midrow, "Active?")
        btn_save = FXButton.new(midrow, "Save")

        btn_save.connect (SEL_COMMAND) do
            self.save_job_info
        end

        row2 = FXHorizontalFrame.new(mainframe,
            LAYOUT_FILL|FRAME_SUNKEN,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)
        @notes_box = FXText.new(row2, :opts => LAYOUT_FILL|TEXT_WORDWRAP)

        self.load_job_info
    end

    def load_job_info
        return @active_chk.setCheck(true) if @jobid == nil
        info = DB.execute("select desc, notes, active from jobs where jobid == #{@jobid};")[0]
        @desc_txt.setText(info[0], true)
        @notes_box.setText(info[1], true)
        if info[2] == 1
            @active_chk.setCheck(true)
        else
            @active_chk.setCheck(false)
        end
    end

    def save_job_info
        fields = {"desc" => @desc_txt, "notes" => @notes_box, "active" => @active_chk.checkState}
        if @jobid == nil
            DB.execute("insert into jobs (custid, desc, notes, active) values (#{@custid}, '#{@desc_txt}', '#{@notes_box}', #{@active_chk.checkState});")
        else
            for x, y in fields
                if x == "active"
                    DB.execute("update jobs set #{x} = #{y} where jobid == #{@jobid};")
                else
                    DB.execute("update jobs set #{x} = '#{y}' where jobid == #{@jobid};")
                end
            end
        end
        self.close(true)
    end


    def create
        super
        show(PLACEMENT_SCREEN)
    end

end


if __FILE__ == $0
    FXApp.new do |app|
        Customers.new(app)
        app.create
        app.run
    end
end
