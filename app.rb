#!/usr/bin/ruby

#--------------------------------------------------------------#
# Requires

require 'sqlite3'
require 'fox16'
require 'fileutils'
include Fox

## Preamble ##

if File.exists?("./customers.db") == false
    db = SQLite3::Database.new "./customers.db"
    db.execute("create virtual table customers using fts5(fname, lname, addr, ph1, ph2, email, cityzip, identifier);")
    db.execute("create virtual table jobs using fts5(custid unindexed, desc, notes, active unindexed, identifier, price unindexed, intake unindexed);")
    db.execute("create table colors(bgcolor integer not null, objcolor integer not null, bgtext integer not null, objtext integer not null);")
    db.execute("insert into colors (bgcolor, objcolor, bgtext, objtext) values (4287843849, 4282488418, 4293190884, 4278190080);")
end

DB = SQLite3::Database.new "./customers.db"

#------------

FileUtils.mkdir("customers") if File.exists?("./customers") == false

#------------

module OS
    def OS.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end
end

#------------
# Not good practice, but whatever.

$bg_color = DB.execute("select bgcolor from colors;")[0][0]
$obj_color = DB.execute("select objcolor from colors;")[0][0]
$bg_text = DB.execute("select bgtext from colors;")[0][0]
$obj_text = DB.execute("select objtext from colors;")[0][0]

#--------------------------------------------------------------#


##  MAIN WINDOW  ##

class Customers < FXMainWindow
    def initialize(app)

####  DEFINE VISUALS ##

        super(app, "Customer Database", :width => 400, :height => 600)
        @logo = FXPNGImage.new(app, File.open("image.png", "rb").read, IMAGE_KEEP)

        mainframe = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        menubar = FXMenuBar.new(mainframe, LAYOUT_TOP|LAYOUT_FILL_X,
                :padTop => 1, :padBottom => 1)

        mainmenu = FXMenuPane.new(mainframe)
        opt1 = FXMenuCommand.new(mainmenu, "&New Customer", nil)
        opt2 = FXMenuCommand.new(mainmenu, "&Open Selection", nil)
        opt3 = FXMenuCommand.new(mainmenu, "&BG Color", nil)
        opt4 = FXMenuCommand.new(mainmenu, "OB&J Color", nil)
        opt6 = FXMenuCommand.new(mainmenu, "BG&Text Color", nil)
        opt7 = FXMenuCommand.new(mainmenu, "OBJTe&xt Color", nil)
        opt5 = FXMenuCommand.new(mainmenu, "&Save Colors", nil)

        title1 = FXMenuTitle.new(menubar, "&Options", nil, mainmenu)

        separator0 = FXSeparator.new(mainframe, LAYOUT_FILL_X|SEPARATOR_LINE)

        img_frame = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0, :hSpacing => 0)
        imgspc1 = FXFrame.new(img_frame, LAYOUT_FILL,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)
        image = FXImageFrame.new(img_frame, @logo, 0,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)
        imgspc2 = FXFrame.new(img_frame, LAYOUT_FILL,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        row1 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 10)

        @which_search = FXDataTarget.new(0)

        spacer = FXHorizontalFrame.new(row1, LAYOUT_FILL_X)
        custie_btn = FXRadioButton.new(row1, "Customers", @which_search, FXDataTarget::ID_OPTION)
        job_btn = FXRadioButton.new(row1, "Jobs", @which_search, FXDataTarget::ID_OPTION + 1)
        active_btn = FXRadioButton.new(row1, "Active Jobs", @which_search, FXDataTarget::ID_OPTION + 2)
        spacer2 = FXHorizontalFrame.new(row1, LAYOUT_FILL_X)

        row2 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        @search_txt = FXTextField.new(row2, 20, :opts => LAYOUT_FILL_X, :padBottom => 5, :padTop => 5, :padLeft => 5, :padRight => 5)
        search_btn = FXButton.new(row2, "Search", :padRight => 10, :padLeft => 10, :padTop => 5, :padBottom => 5, :opts => JUSTIFY_NORMAL, :width => 20, :height => 10)

        row4 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        @customers_list = FXList.new(row4, :opts => LAYOUT_FILL|LIST_SINGLESELECT)

#### COLORS ##

        @logo.blend($bg_color)

        bg_list = [ mainframe, row1, row2, row4, spacer, spacer2, custie_btn, job_btn, active_btn, menubar, title1, img_frame, imgspc1, imgspc2]
        obj_list = [ @search_txt, @customers_list, search_btn, mainmenu, opt1, opt2, opt3, opt4, opt5, opt6, opt7]
        bgtext_list = [title1, custie_btn, job_btn, active_btn]
        objtext_list = [opt1, opt2, opt3, opt4, opt5, opt6, opt7, @search_txt, search_btn, @customers_list]

        bg_list.each { |i| i.backColor=$bg_color }
        obj_list.each { |i| i.backColor=$obj_color }
        bgtext_list.each { |i| i.textColor=$bg_text }
        objtext_list.each { |i| i.textColor=$obj_text }

####  FUNCTIONALITY ##

        @customers_list.connect(SEL_SELECTED) do |x, y, z|
            @which_result = @customers_list.getItemData(z)
            @jobid = @customers_list.getItemData(z)[1] if @which_result != nil
        end

        @customers_list.connect(SEL_DOUBLECLICKED) { self.results_info }

        @customers_list.connect(SEL_KEYPRESS) do |x, y, z|
          if z.code == 65535 and @which_search.value == 2
            DB.execute("update jobs set active = NOT active where rowid == #{@jobid};")
            self.search_items
          end
        end

        @search_txt.connect (SEL_COMMAND) { self.search_items }
        @search_txt.connect (SEL_CHANGED) { self.search_items }

        opt1.connect (SEL_COMMAND) { self.new_customer }
        opt2.connect (SEL_COMMAND) { self.results_info }

        def choose_color(list, type, variable)
            clr_box = FXColorDialog.new(self, "Select Color")
            clr_box.opaqueOnly = true

            if type == 0
                clr_box.connect(SEL_COMMAND) { list.each { |i| i.backColor=clr_box.rgba } }
            else
                clr_box.connect(SEL_COMMAND) { list.each { |i| i.textColor=clr_box.rgba } }
            end

            clr_box.children[0].acceptButton.connect(SEL_COMMAND) do
                case variable
                when 0
                    $bg_color = clr_box.rgba
                    list.each { |i| i.backColor=$bg_color }
                when 1
                    $obj_color = clr_box.rgba
                    list.each { |i| i.backColor=$obj_color }
                when 2
                    $bg_text = clr_box.rgba
                    list.each { |i| i.textColor=$bg_text }
                when 3
                    $obj_text = clr_box.rgba
                    list.each { |i| i.textColor=$obj_text }
                end

                clr_box.close(true)
            end

            clr_box.children[0].cancelButton.connect(SEL_COMMAND) do
                case variable
                when 0
                    list.each { |i| i.backColor=$bg_color }
                when 1
                    list.each { |i| i.backColor=$obj_color }
                when 2
                    list.each { |i| i.textColor=$bg_text }
                when 3
                    list.each { |i| i.textColor=$obj_text }
                end
                clr_box.close(true)
            end

            clr_box.create
            clr_box.show
        end

        opt3.connect(SEL_COMMAND) { choose_color(bg_list, 0, 0) }

        opt4.connect(SEL_COMMAND) { choose_color(obj_list, 0, 1) }

        opt6.connect(SEL_COMMAND) { choose_color(bgtext_list, 1, 2) }

        opt7.connect(SEL_COMMAND) { choose_color(objtext_list, 1, 3) }

        opt5.connect(SEL_COMMAND) do
            DB.execute("delete from colors;")
            DB.execute("insert into colors (bgcolor, objcolor, bgtext, objtext) values (#{$bg_color}, #{$obj_color}, #{$bg_text}, #{$obj_text});")
        end

        @which_search.connect (SEL_COMMAND) { self.search_items }

####  INITIAL LOAD ##
        
        @which_search.value = 2
        self.search_items
    end

####  FUNCTIONS ##

    def search_items
        return if @search_txt.text == "*"
        return self.load_customers if @search_txt.text == "" and @which_search.value == 0
        @customers_list.clearItems
        return @customers_list.appendItem("No results.") if @search_txt.text == "" and @which_search.value == 1

        if @which_search.value == 0
            begin
                results = DB.execute("select fname, lname, ph1, rowid from customers where customers match '#{@search_txt}*';")
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
                results = DB.execute("select custid, desc, active, rowid, intake, price from jobs where jobs match '#{@search_txt}*';") if @which_search.value == 1
                results = DB.execute("select custid, desc, active, rowid, intake, price from jobs where active == 1;") if @which_search.value == 2
            rescue
                results = []
            end

            if results.length > 0
                for i in results
                    customer = DB.execute("select fname, lname from customers where rowid == #{i[0]};")[0]
                    desc = i[1]
                    desc = "[#{i[4]}] [$#{i[5]}] " + desc if i[2] == 1
                    @customers_list.appendItem("#{desc}", nil, [i[0], i[3]])
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
        info_win.connect (SEL_CLOSE) { info_win.close; self.search_items }
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
        win2.connect(SEL_CLOSE) { win2.close; self.search_items if @which_search.value == 0 }
    end

    def create
        super; show(PLACEMENT_SCREEN)
    end
end


##  CUSTOMER INFO WINDOW  ##

class Customer_Jobs < FXMainWindow
    def initialize(app, custid)

####  WINDOW VARIABLES ##

        @app = app
        @custid = custid
        @custname = DB.execute("select fname, lname from customers where rowid == #{@custid};")[0].join(" ") if @custid != nil
        @custname = "NEW CUSTOMER" if @custid == nil

####  DEFINE VISUALS ##

        super(app, "Customer: #{@custname}", :width=> 450, :height => 400)

        mainframe = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y, 
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        row1 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X, 
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        column1 = FXVerticalFrame.new(row1, LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH, 
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        fname_lbl = FXLabel.new(column1, "First name:", :padTop => 4, :padBottom => 4)
        lname_lbl = FXLabel.new(column1, "Last name:", :padTop => 4, :padBottom => 4)
        addr_lbl = FXLabel.new(column1, "Address:", :padTop => 4, :padBottom => 4)
        cityzip_lbl = FXLabel.new(column1, "City, Zip:", :padTop => 4, :padBottom => 4)
        ph1_lbl = FXLabel.new(column1, "Phone 1:", :padTop => 4, :padBottom => 4)
        ph2_lbl = FXLabel.new(column1, "Phone 2:", :padTop => 4, :padBottom => 4)
        email_lbl = FXLabel.new(column1, "E-mail:", :padTop => 4, :padBottom => 4)

        column2 = FXVerticalFrame.new(row1, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        @fname_txt = FXTextField.new(column2, 26, :opts => LAYOUT_FILL_X, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        @lname_txt = FXTextField.new(column2, 26, :opts => LAYOUT_FILL_X, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        @addr_txt = FXTextField.new(column2, 26, :opts => LAYOUT_FILL_X, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        @cityzip_txt = FXTextField.new(column2, 26, :opts => LAYOUT_FILL_X, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        @ph1_txt = FXTextField.new(column2, 26, :opts => LAYOUT_FILL_X, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        @ph2_txt = FXTextField.new(column2, 26, :opts => LAYOUT_FILL_X, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        @email_txt = FXTextField.new(column2, 26, :opts => LAYOUT_FILL_X, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        separator = FXSeparator.new(mainframe, LAYOUT_FILL_X)

        column3 = FXVerticalFrame.new(row1, LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH|PACK_UNIFORM_HEIGHT,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        save_btn = FXButton.new(column3, "Save", :opts => JUSTIFY_NORMAL, :padTop => 4, :padBottom => 4)
        delete_cust = FXButton.new(column3, "Delete", :opts => JUSTIFY_NORMAL, :padTop => 4, :padBottom => 4)
        spacer1 = FXFrame.new(column3, LAYOUT_FILL_Y)
        fold_btn = FXButton.new(column3, "Folder", :opts => JUSTIFY_NORMAL, :padTop => 4, :padBottom => 4)
        spacer2 = FXFrame.new(column3, LAYOUT_FILL_Y)
        id_lbl = FXLabel.new(column3, "Cust ID:", :opts => JUSTIFY_NORMAL)
        @custid_txt = FXTextField.new(column3, 7, :opts => LAYOUT_FILL_X, :padTop => 4, :padBottom => 4, :padRight => 5, :padLeft => 5)

        row2 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        column4 = FXVerticalFrame.new(row2, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        @job_list = FXList.new(column4, :opts => LAYOUT_FILL|LIST_SINGLESELECT, :width => 315, :height => 175)

        column5 = FXVerticalFrame.new(row2, LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        new_btn = FXButton.new(column5, "New", :opts => JUSTIFY_NORMAL, :padTop => 4, :padBottom => 4)
        edit_btn = FXButton.new(column5, "Edit", :opts => JUSTIFY_NORMAL, :padTop => 4, :padBottom => 4)
        active_button = FXButton.new(column5, "Active", :opts => JUSTIFY_NORMAL, :padTop => 4, :padBottom => 4)
        scope_btn = FXButton.new(column5, "Images", :opts => JUSTIFY_NORMAL, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        spacer3 = FXFrame.new(column5, LAYOUT_FILL_Y)
        delete_job = FXButton.new(column5, "Delete", :opts => JUSTIFY_NORMAL, :padTop => 4, :padBottom => 4)
        spacer4 = FXFrame.new(column5, LAYOUT_FILL_Y)

#### COLORS ##

        bg_list = [ mainframe, row1, row2, column1, column2, column3, column4, column5, separator, spacer1, spacer2, spacer3, spacer4, fname_lbl, lname_lbl, addr_lbl, cityzip_lbl, ph1_lbl, ph2_lbl, email_lbl, id_lbl ]
        obj_list = [ @fname_txt, @lname_txt, @addr_txt, @cityzip_txt, @ph1_txt, @ph2_txt, @email_txt, save_btn, delete_cust, fold_btn, @custid_txt, @job_list, new_btn, edit_btn, active_button, scope_btn, delete_job ]
        bgtext_list = [fname_lbl, lname_lbl, addr_lbl, cityzip_lbl, ph1_lbl, ph2_lbl, email_lbl, id_lbl]
        objtext_list = [@fname_txt, @lname_txt, @addr_txt, @cityzip_txt, @ph1_txt, @ph2_txt, @email_txt, save_btn, delete_cust, fold_btn, @custid_txt, @job_list, new_btn, edit_btn, active_button, scope_btn, delete_job]

        bg_list.each { |i| i.backColor=$bg_color }
        obj_list.each { |i| i.backColor=$obj_color }
        bgtext_list.each { |i| i.textColor=$bg_text }
        objtext_list.each { |i| i.textColor=$obj_text }

####  FUNCTIONALITY ##

        new_btn.disable if @custid == nil
        edit_btn.disable if @custid == nil
        active_button.disable if @custid == nil
        scope_btn.disable if @custid == nil
        delete_job.disable if @custid == nil
        delete_cust.disable if @custid == nil

        @job_list.connect(SEL_SELECTED) { |x, y, z| @jobid = @job_list.getItemData(z) }
        @job_list.connect(SEL_DOUBLECLICKED) { self.edit_job(@jobid) }

        delete_cust.connect (SEL_COMMAND) do
            check = FXMessageBox.question(app, MBOX_YES_NO, "Are you sure?", "Are you sure? This can't be undone!")
            if check == MBOX_CLICKED_YES
                DB.execute("delete from customers where rowid == #{@custid}")
                DB.execute("delete from jobs where custid == #{@custid}")
                self.close(true)
            end
        end

        new_btn.connect (SEL_COMMAND) { self.edit_job(nil) }

        edit_btn.connect (SEL_COMMAND) { self.edit_job(@jobid) }

        save_btn.connect (SEL_COMMAND) { self.save_custie }

        fold_btn.connect (SEL_COMMAND) { system("start customers\\#{@lname_txt.text}_#{@fname_txt.text}") if OS.windows? == true }

        active_button.connect (SEL_COMMAND) do
            DB.execute("update jobs set active = NOT active where rowid == #{@jobid};")
            self.load_jobs
        end

        scope_btn.connect(SEL_COMMAND) { self.open_scope }

        delete_job.connect (SEL_COMMAND) do
            check = FXMessageBox.question(app, MBOX_YES_NO, "Are you sure?", "Are you sure? This can't be undone!")
            if check == MBOX_CLICKED_YES
                DB.execute("delete from jobs where rowid == #{@jobid}")
            end
            self.load_jobs
        end

####  INITIAL LOAD ##
        
        self.load_custie
        self.load_jobs
    end

####  FUNCTIONS  ##

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

        if @custid == nil
            custid = DB.execute("select rowid from customers order by rowid desc limit 1;")[0][0]
            edit_win = Customer_Jobs.new(@app, custid); edit_win.create
        end
    end

    def load_jobs
        return if @custid == nil
        @job_list.clearItems
        jobs = DB.execute("select desc, rowid, active, identifier, intake, price from jobs where custid == #{@custid};")
        jobs.reverse!
        for i in jobs
            desc = "#{i[0]}"
            desc = "[#{i[4]}] [$#{i[5]}] " + desc if i[2] == 1
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
        job_win.connect(SEL_CLOSE) do
            job_win.close
            begin
                self.load_jobs
            rescue
                puts "=> Rescue from line 292 in edit_job:"
                puts "   Parent closed before child."
            end
        end
    end

    def open_scope
        directory = "customers/#{@lname_txt.text}_#{@fname_txt.text}"
        FileUtils.mkdir(directory) if File.exists?("./#{directory}") == false
        if OS.windows? == true
            FileUtils.mv(directory, "customers/Customer")
            a = `start /wait customers/dv.exe.lnk`
            FileUtils.mv("customers/Customer", directory)
        end
    end

    def create
        super; show(PLACEMENT_SCREEN)
    end

end


####  JOB WINDOW  ##

class Job_Edit < FXMainWindow
    def initialize(app, custid, jobid)

####  WINDOW VARIABLES ##

        @custid = custid
        @jobid = jobid
        @custname = DB.execute("select fname, lname from customers where rowid == #{@custid};")[0].join(" ")

####  DEFINE VISUALS ##

        super(app, "Edit Job", :width=> 350, :height => 300)

        mainframe = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        row1 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)
        
        column1 = FXVerticalFrame.new(row1, LAYOUT_FILL_X|LAYOUT_FILL_Y,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        intake_lbl = FXLabel.new(column1, "Intake Date:", :padTop => 4, :padBottom => 4)
        fname_lbl = FXLabel.new(column1, "Customer:", :padTop => 4, :padBottom => 4)
        desc_lbl = FXLabel.new(column1, "Job Desc:", :padTop => 4, :padBottom => 4)
        cost_lbl = FXLabel.new(column1, "Job price:", :padTop => 4, :padBottom => 4)

        column2 = FXVerticalFrame.new(row1, LAYOUT_FILL_X,
            :padLeft => 5, :padRight => 5, :padTop => 5, :padBottom => 5)

        row2 = FXHorizontalFrame.new(column2, LAYOUT_FILL_X,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        @intake_txt = FXTextField.new(row2, 11, :opts => 0, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        spacer1 = FXFrame.new(row2, LAYOUT_FILL_X)
        jobid_lbl = FXLabel.new(row2, "Job ID:", :padTop => 4, :padBottom => 4)
        @jobid_txt = FXTextField.new(row2, 7, :opts => 0, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)

        row3 = FXHorizontalFrame.new(column2, LAYOUT_FILL_X,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        name_lbl = FXLabel.new(row3, @custname, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        @desc_txt = FXTextField.new(column2, 30, :opts => LAYOUT_FILL_X, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)

        row4 = FXHorizontalFrame.new(column2, LAYOUT_FILL_X,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)

        @price_txt = FXTextField.new(row4, 7, :opts => 0, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)

        spacer2 = FXFrame.new(row4, LAYOUT_FILL_X)
        @active_chk = FXCheckButton.new(row4, "Active?", :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)
        btn_save = FXButton.new(row4, "Save", :opts => JUSTIFY_NORMAL, :padRight => 5, :padLeft => 5, :padTop => 4, :padBottom => 4)

        row5 = FXHorizontalFrame.new(mainframe, LAYOUT_FILL,
            :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0)
        @notes_box = FXText.new(row5, :opts => LAYOUT_FILL|TEXT_WORDWRAP)

#### COLORS ##

        bg_list = [ mainframe, row1, row2, row3, row4, row5, column1, column2, spacer1, spacer2, intake_lbl, fname_lbl, desc_lbl, cost_lbl, jobid_lbl, name_lbl, @active_chk ]
        obj_list = [ @intake_txt, @jobid_txt, @desc_txt, @price_txt, @notes_box, btn_save, name_lbl ]
        bgtext_list = [intake_lbl, fname_lbl, desc_lbl, cost_lbl, jobid_lbl, @active_chk]
        objtext_list = [@intake_txt, @jobid_txt, name_lbl, @desc_txt, @price_txt, btn_save, @notes_box]

        bg_list.each { |i| i.backColor=$bg_color }
        obj_list.each { |i| i.backColor=$obj_color }
        bgtext_list.each { |i| i.textColor=$bg_text }
        objtext_list.each { |i| i.textColor=$obj_text }

####  FUNCTIONALITY  ##

        btn_save.connect (SEL_COMMAND) { self.save_job_info }

####  INITIAL LOAD  ##

        self.load_job_info
    end

####  FUNCTIONS  ##

    def load_job_info
        @active_chk.setCheck(true)
        @intake_txt.setText("#{Time.now.strftime('%m/%d/%y')}", true); return if @jobid == nil
        info = DB.execute("select desc, notes, active, identifier, intake, price from jobs where rowid == #{@jobid};")[0]
        @desc_txt.setText(info[0], true)
        @notes_box.setText(info[1], true)
        @jobid_txt.setText(info[3], true)
        @intake_txt.setText(info[4], true)
        @price_txt.setText(info[5], true)
        @active_chk.setCheck(false) if info[2] == 0
    end

    def save_job_info
        fields = {"desc" => @desc_txt, "notes" => @notes_box, "active" => @active_chk.checkState, "identifier" => @jobid_txt, "intake" => @intake_txt, "price" => @price_txt}
        if @jobid == nil
            DB.execute("insert into jobs (custid, desc, notes, active, identifier, intake, price) values (#{@custid}, \"#{@desc_txt}\", \"#{@notes_box}\", #{@active_chk.checkState}, '#{@jobid_txt}', '#{@intake_txt}', '#{@price_txt}');")
        else
            for x, y in fields
                if x == "active"
                    DB.execute("update jobs set #{x} = #{y} where rowid == #{@jobid};")
                else
                    DB.execute("update jobs set #{x} = \"#{y}\" where rowid == #{@jobid};")
                end
            end
        end
        self.close(true)
    end

    def create
        super; show(PLACEMENT_SCREEN)
    end

end




#--------------------------------#
# Run

if __FILE__ == $0
    FXApp.new do |app|
        Customers.new(app)
        app.create
        app.run
    end
end

#--------------------------------#
# EOF
